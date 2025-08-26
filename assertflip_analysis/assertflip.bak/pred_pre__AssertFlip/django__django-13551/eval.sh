#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 7f9e4524d6b23424cf44fbe1bf1f4e70f6bb066e >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 7f9e4524d6b23424cf44fbe1bf1f4e70f6bb066e
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13551.py
new file mode 100644
index e69de29..abb8619 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13551.py
@@ -0,0 +1,27 @@
+from django.test import TestCase
+from django.contrib.auth.models import User
+from django.contrib.auth.tokens import default_token_generator
+from django.utils.http import urlsafe_base64_encode
+from django.utils.encoding import force_bytes
+
+class PasswordResetTokenTest(TestCase):
+    def setUp(self):
+        # Create a user with an email address
+        self.user = User.objects.create_user(username='testuser', email='original@example.com', password='password123')
+        self.uidb64 = urlsafe_base64_encode(force_bytes(self.user.pk))
+        self.token = default_token_generator.make_token(self.user)
+
+    def test_password_reset_token_invalid_after_email_change(self):
+        # Change the user's email address
+        self.user.email = 'new@example.com'
+        self.user.save()
+
+        # Attempt to use the password reset token generated before the email change
+        is_token_valid = default_token_generator.check_token(self.user, self.token)
+
+        # Assert that the token is correctly rejected after the email change
+        self.assertFalse(is_token_valid)
+
+    def tearDown(self):
+        # Clean up the user created for the test
+        self.user.delete()

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/auth/tokens\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13551
cat coverage.cover
git checkout 7f9e4524d6b23424cf44fbe1bf1f4e70f6bb066e
git apply /root/pre_state.patch
