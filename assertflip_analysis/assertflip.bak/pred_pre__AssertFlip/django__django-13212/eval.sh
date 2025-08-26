#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD f4e93919e4608cfc50849a1f764fd856e0917401 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff f4e93919e4608cfc50849a1f764fd856e0917401
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13212.py
new file mode 100644
index e69de29..ad69470 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13212.py
@@ -0,0 +1,19 @@
+from django.test import SimpleTestCase
+from django.core.exceptions import ValidationError
+from django.core.validators import EmailValidator
+
+class EmailValidatorTest(SimpleTestCase):
+    def test_email_validator_includes_value_in_error(self):
+        """
+        Test that the EmailValidator raises a ValidationError including
+        the provided value in the error message.
+        """
+        validator = EmailValidator(message="%(value)s is not a valid email address.")
+        invalid_email = "invalid-email"
+
+        with self.assertRaises(ValidationError) as cm:
+            validator(invalid_email)
+
+        error_message = str(cm.exception)
+        # The error message should include the invalid value.
+        self.assertIn(invalid_email, error_message)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/forms/fields\.py|django/core/validators\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13212
cat coverage.cover
git checkout f4e93919e4608cfc50849a1f764fd856e0917401
git apply /root/pre_state.patch
