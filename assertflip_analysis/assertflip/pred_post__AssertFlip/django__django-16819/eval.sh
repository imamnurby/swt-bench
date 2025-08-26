#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 0b0998dc151feb77068e2387c34cc50ef6b356ae >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 0b0998dc151feb77068e2387c34cc50ef6b356ae
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/migrations/operations/models.py b/django/db/migrations/operations/models.py
--- a/django/db/migrations/operations/models.py
+++ b/django/db/migrations/operations/models.py
@@ -861,6 +861,11 @@ def describe(self):
     def migration_name_fragment(self):
         return "%s_%s" % (self.model_name_lower, self.index.name.lower())
 
+    def reduce(self, operation, app_label):
+        if isinstance(operation, RemoveIndex) and self.index.name == operation.name:
+            return []
+        return super().reduce(operation, app_label)
+
 
 class RemoveIndex(IndexOperation):
     """Remove an index from a model."""

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16819.py
new file mode 100644
index e69de29..9745fce 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16819.py
@@ -0,0 +1,37 @@
+from django.test import SimpleTestCase
+from django.db.migrations.optimizer import MigrationOptimizer
+from django.db.migrations.operations.models import AddIndex, RemoveIndex
+from django.db.migrations.state import ProjectState
+from django.db import models
+
+class MigrationOptimizerTest(SimpleTestCase):
+    def test_add_remove_index_not_optimized(self):
+        """
+        Test that AddIndex followed by RemoveIndex on the same model and index
+        are optimized away, ensuring the bug is fixed.
+        """
+        # Setup: Define a model and an index
+        class TestModel(models.Model):
+            field = models.IntegerField()
+
+            class Meta:
+                app_label = 'test_app'
+
+        index = models.Index(fields=['field'], name='test_index')
+
+        # Create AddIndex and RemoveIndex operations
+        add_index_op = AddIndex('TestModel', index)
+        remove_index_op = RemoveIndex('TestModel', 'test_index')
+
+        # List of operations to optimize
+        operations = [add_index_op, remove_index_op]
+
+        # Initialize the optimizer
+        optimizer = MigrationOptimizer()
+
+        # Optimize the operations
+        optimized_operations = optimizer.optimize(operations, 'test_app')
+
+        # Assert that both operations are not present, indicating the bug is fixed
+        self.assertNotIn(add_index_op, optimized_operations)
+        self.assertNotIn(remove_index_op, optimized_operations)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/migrations/operations/models\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16819
cat coverage.cover
git checkout 0b0998dc151feb77068e2387c34cc50ef6b356ae
git apply /root/pre_state.patch
