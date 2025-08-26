#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD bb64b99b78a579cb2f6178011a4cf9366e634438 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff bb64b99b78a579cb2f6178011a4cf9366e634438
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13786.py
new file mode 100644
index e69de29..b351ac2 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13786.py
@@ -0,0 +1,31 @@
+from django.test import SimpleTestCase
+from django.db.migrations.state import ModelState
+from django.db.migrations.operations.models import CreateModel, AlterModelOptions
+
+class CreateModelReduceTest(SimpleTestCase):
+    def test_reduce_with_empty_alter_model_options(self):
+        # Setup: CreateModel with non-empty options
+        create_model_op = CreateModel(
+            name='TestModel',
+            fields=[],
+            options={'verbose_name': 'Test Model'},
+        )
+
+        # Setup: AlterModelOptions with empty options
+        alter_model_options_op = AlterModelOptions(
+            name='TestModel',
+            options={},
+        )
+
+        # Perform the reduction
+        reduced_operations = create_model_op.reduce(alter_model_options_op, 'test_app')
+
+        # There should be one operation in the reduced list
+        self.assertEqual(len(reduced_operations), 1)
+
+        # The reduced operation should be a CreateModel
+        reduced_create_model_op = reduced_operations[0]
+        self.assertIsInstance(reduced_create_model_op, CreateModel)
+
+        # The options should be empty after reduction
+        self.assertEqual(reduced_create_model_op.options, {})

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/migrations/operations/models\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13786
cat coverage.cover
git checkout bb64b99b78a579cb2f6178011a4cf9366e634438
git apply /root/pre_state.patch
