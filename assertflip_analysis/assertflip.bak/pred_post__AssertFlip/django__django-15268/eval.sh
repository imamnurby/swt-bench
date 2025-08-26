#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 0ab58c120939093fea90822f376e1866fc714d1f >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 0ab58c120939093fea90822f376e1866fc714d1f
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/migrations/operations/models.py b/django/db/migrations/operations/models.py
--- a/django/db/migrations/operations/models.py
+++ b/django/db/migrations/operations/models.py
@@ -34,9 +34,12 @@ def references_model(self, name, app_label):
     def reduce(self, operation, app_label):
         return (
             super().reduce(operation, app_label) or
-            not operation.references_model(self.name, app_label)
+            self.can_reduce_through(operation, app_label)
         )
 
+    def can_reduce_through(self, operation, app_label):
+        return not operation.references_model(self.name, app_label)
+
 
 class CreateModel(ModelOperation):
     """Create a model's table."""
@@ -528,6 +531,14 @@ def describe(self):
     def migration_name_fragment(self):
         return 'alter_%s_%s' % (self.name_lower, self.option_name)
 
+    def can_reduce_through(self, operation, app_label):
+        return (
+            super().can_reduce_through(operation, app_label) or (
+                isinstance(operation, AlterTogetherOptionOperation) and
+                type(operation) is not type(self)
+            )
+        )
+
 
 class AlterUniqueTogether(AlterTogetherOptionOperation):
     """

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15268.py
new file mode 100644
index e69de29..65aa106 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15268.py
@@ -0,0 +1,34 @@
+from django.test import SimpleTestCase
+from django.db.migrations.optimizer import MigrationOptimizer
+from django.db.migrations.operations.models import AlterUniqueTogether, AlterIndexTogether
+
+class MigrationOptimizerTest(SimpleTestCase):
+    def test_optimize_redundant_operations(self):
+        # Setup: Create a list of redundant operations
+        operations = [
+            AlterUniqueTogether(name='mymodel', unique_together=set()),
+            AlterIndexTogether(name='mymodel', index_together=set()),
+            AlterUniqueTogether(name='mymodel', unique_together={("col",)}),
+            AlterIndexTogether(name='mymodel', index_together={("col",)}),
+        ]
+
+        # Initialize the MigrationOptimizer
+        optimizer = MigrationOptimizer()
+
+        # Mock app label
+        app_label = 'test_app'
+
+        # Call the optimize method
+        optimized_operations = optimizer.optimize(operations, app_label)
+
+        # Assertions to expose the bug
+        # The length of optimized_operations should be 2 after optimization
+        self.assertEqual(len(optimized_operations), 2)
+
+        # The first operation should be AlterUniqueTogether with unique_together={("col",)}
+        self.assertIsInstance(optimized_operations[0], AlterUniqueTogether)
+        self.assertEqual(optimized_operations[0].unique_together, {("col",)})
+
+        # The second operation should be AlterIndexTogether with index_together={("col",)}
+        self.assertIsInstance(optimized_operations[1], AlterIndexTogether)
+        self.assertEqual(optimized_operations[1].index_together, {("col",)})

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/migrations/operations/models\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15268
cat coverage.cover
git checkout 0ab58c120939093fea90822f376e1866fc714d1f
git apply /root/pre_state.patch
