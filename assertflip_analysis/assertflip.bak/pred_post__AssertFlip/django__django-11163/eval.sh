#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD e6588aa4e793b7f56f4cadbfa155b581e0efc59a >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff e6588aa4e793b7f56f4cadbfa155b581e0efc59a
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/forms/models.py b/django/forms/models.py
--- a/django/forms/models.py
+++ b/django/forms/models.py
@@ -83,7 +83,7 @@ def model_to_dict(instance, fields=None, exclude=None):
     for f in chain(opts.concrete_fields, opts.private_fields, opts.many_to_many):
         if not getattr(f, 'editable', False):
             continue
-        if fields and f.name not in fields:
+        if fields is not None and f.name not in fields:
             continue
         if exclude and f.name in exclude:
             continue

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11163.py
new file mode 100644
index e69de29..756a0d0 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11163.py
@@ -0,0 +1,23 @@
+from django.test import SimpleTestCase
+from django.forms.models import model_to_dict
+from django.db import models
+
+# Define a mock model for testing
+class MockModel(models.Model):
+    field1 = models.CharField(max_length=100)
+    field2 = models.IntegerField()
+    field3 = models.BooleanField()
+
+    class Meta:
+        app_label = 'mock_app'
+
+class ModelToDictBugTest(SimpleTestCase):
+    def test_model_to_dict_with_empty_fields_list(self):
+        # Create a mock model instance
+        instance = MockModel(field1="test", field2=123, field3=True)
+
+        # Call model_to_dict with an empty fields list
+        result = model_to_dict(instance, fields=[])
+
+        # Assert that the returned dictionary is empty
+        self.assertEqual(result, {})

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/forms/models\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11163
cat coverage.cover
git checkout e6588aa4e793b7f56f4cadbfa155b581e0efc59a
git apply /root/pre_state.patch
