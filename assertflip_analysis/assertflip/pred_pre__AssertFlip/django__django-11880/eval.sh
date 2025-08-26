#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 06909fe084f87a65459a83bd69d7cdbe4fce9a7c >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 06909fe084f87a65459a83bd69d7cdbe4fce9a7c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11880.py
new file mode 100644
index e69de29..721881d 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11880.py
@@ -0,0 +1,20 @@
+from django.test import SimpleTestCase
+import copy
+from django.forms import CharField
+
+class FieldDeepCopyTest(SimpleTestCase):
+    def test_deepcopy_error_messages(self):
+        # Create a CharField with custom error messages
+        original_field = CharField(error_messages={'required': 'This field is required.'})
+
+        # Perform a deep copy of the original field
+        copied_field = copy.deepcopy(original_field)
+
+        # Modify the error_messages in the copied field
+        copied_field.error_messages['required'] = 'This field is absolutely required.'
+
+        # Assert that the original field's error_messages have not changed
+        self.assertEqual(
+            original_field.error_messages['required'],
+            'This field is required.'
+        )

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/forms/fields\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11880
cat coverage.cover
git checkout 06909fe084f87a65459a83bd69d7cdbe4fce9a7c
git apply /root/pre_state.patch
