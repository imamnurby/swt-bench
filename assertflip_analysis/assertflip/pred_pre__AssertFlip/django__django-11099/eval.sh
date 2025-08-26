#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d26b2424437dabeeca94d7900b37d2df4410da0c >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d26b2424437dabeeca94d7900b37d2df4410da0c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11099.py
new file mode 100644
index e69de29..bb58814 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11099.py
@@ -0,0 +1,18 @@
+from django.test import SimpleTestCase
+from django.contrib.auth.validators import ASCIIUsernameValidator, UnicodeUsernameValidator
+from django.core.exceptions import ValidationError
+
+class UsernameValidatorTests(SimpleTestCase):
+    def test_ascii_username_validator_allows_trailing_newline(self):
+        validator = ASCIIUsernameValidator()
+        # Username with trailing newline
+        username_with_newline = "validusername\n"
+        with self.assertRaises(ValidationError, msg="ASCIIUsernameValidator should not accept username with trailing newline"):
+            validator(username_with_newline)
+
+    def test_unicode_username_validator_allows_trailing_newline(self):
+        validator = UnicodeUsernameValidator()
+        # Username with trailing newline
+        username_with_newline = "validusername\n"
+        with self.assertRaises(ValidationError, msg="UnicodeUsernameValidator should not accept username with trailing newline"):
+            validator(username_with_newline)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/auth/validators\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11099
cat coverage.cover
git checkout d26b2424437dabeeca94d7900b37d2df4410da0c
git apply /root/pre_state.patch
