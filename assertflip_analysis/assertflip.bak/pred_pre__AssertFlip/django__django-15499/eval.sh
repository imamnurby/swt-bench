#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d90e34c61b27fba2527834806639eebbcfab9631 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d90e34c61b27fba2527834806639eebbcfab9631
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15499.py
new file mode 100644
index e69de29..4890d8e 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15499.py
@@ -0,0 +1,37 @@
+from django.test import SimpleTestCase
+from django.db import models
+from django.db.migrations.operations.models import CreateModel, AlterModelManagers
+from django.db.migrations.optimizer import MigrationOptimizer
+
+class MigrationOptimizationTest(SimpleTestCase):
+    def test_create_model_and_alter_model_managers_not_optimized(self):
+        """
+        Test that CreateModel followed by AlterModelManagers is optimized
+        into a single CreateModel operation, exposing the bug.
+        """
+        # Define a CreateModel operation
+        create_model_op = CreateModel(
+            name='TestModel',
+            fields=[('id', models.AutoField(primary_key=True))],
+            options={},
+            managers=[]
+        )
+
+        # Define an AlterModelManagers operation
+        alter_managers_op = AlterModelManagers(
+            name='TestModel',
+            managers=[('objects', models.Manager())]
+        )
+
+        # Create a list of operations simulating a migration
+        operations = [create_model_op, alter_managers_op]
+
+        # Run the optimizer
+        optimizer = MigrationOptimizer()
+        optimized_operations = optimizer.optimize(operations, app_label='test_app')
+
+        # Assert that the operations are reduced correctly
+        # The operations should be reduced to a single CreateModel
+        self.assertEqual(len(optimized_operations), 1)
+        self.assertIsInstance(optimized_operations[0], CreateModel)
+        self.assertEqual(optimized_operations[0].managers, [('objects', models.Manager())])

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/migrations/operations/models\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15499
cat coverage.cover
git checkout d90e34c61b27fba2527834806639eebbcfab9631
git apply /root/pre_state.patch
