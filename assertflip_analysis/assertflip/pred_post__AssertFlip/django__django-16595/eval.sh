#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD f9fe062de5fc0896d6bbbf3f260b5c44473b3c77 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff f9fe062de5fc0896d6bbbf3f260b5c44473b3c77
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/migrations/operations/fields.py b/django/db/migrations/operations/fields.py
--- a/django/db/migrations/operations/fields.py
+++ b/django/db/migrations/operations/fields.py
@@ -247,9 +247,9 @@ def migration_name_fragment(self):
         return "alter_%s_%s" % (self.model_name_lower, self.name_lower)
 
     def reduce(self, operation, app_label):
-        if isinstance(operation, RemoveField) and self.is_same_field_operation(
-            operation
-        ):
+        if isinstance(
+            operation, (AlterField, RemoveField)
+        ) and self.is_same_field_operation(operation):
             return [operation]
         elif (
             isinstance(operation, RenameField)

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16595.py
new file mode 100644
index e69de29..4cec1a4 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16595.py
@@ -0,0 +1,40 @@
+from django.test import SimpleTestCase
+from django.db import migrations, models
+
+class MigrationOptimizerBugTest(SimpleTestCase):
+    def test_alterfield_operations_not_reduced(self):
+        # Setup: Define multiple AlterField operations on the same field
+        operations = [
+            migrations.AlterField(
+                model_name="book",
+                name="title",
+                field=models.CharField(max_length=128, null=True),
+            ),
+            migrations.AlterField(
+                model_name="book",
+                name="title",
+                field=models.CharField(max_length=128, null=True, help_text="help"),
+            ),
+            migrations.AlterField(
+                model_name="book",
+                name="title",
+                field=models.CharField(max_length=128, null=True, help_text="help", default=None),
+            ),
+        ]
+
+        # Simulate the optimizer's behavior by directly calling the reduce method
+        reduced_operations = []
+        for op in operations:
+            if reduced_operations:
+                last_op = reduced_operations[-1]
+                reduced = last_op.reduce(op, "books")
+                if reduced is not None and isinstance(reduced, list):
+                    reduced_operations.pop()
+                    reduced_operations.extend(reduced)
+                else:
+                    reduced_operations.append(op)
+            else:
+                reduced_operations.append(op)
+
+        # Assert: The operations should be reduced to a single operation
+        self.assertEqual(len(reduced_operations), 1)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/migrations/operations/fields\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16595
cat coverage.cover
git checkout f9fe062de5fc0896d6bbbf3f260b5c44473b3c77
git apply /root/pre_state.patch
