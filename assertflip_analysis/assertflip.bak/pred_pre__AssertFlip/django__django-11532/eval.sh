#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a5308514fb4bc5086c9a16a8a24a945eeebb073c >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a5308514fb4bc5086c9a16a8a24a945eeebb073c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11532.py
new file mode 100644
index e69de29..1f94e5f 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11532.py
@@ -0,0 +1,19 @@
+from django.test import SimpleTestCase
+from unittest.mock import patch
+from django.core.mail import EmailMessage
+
+class EmailMessageTest(SimpleTestCase):
+    def test_unicode_dns_message_id_encoding(self):
+        """
+        Test that when the DNS_NAME is set to a non-ASCII value and the email encoding is set to 'iso-8859-1',
+        the Message-ID header is correctly encoded, ensuring the bug is fixed.
+        """
+        with patch("django.core.mail.message.DNS_NAME", "漢字"):
+            email = EmailMessage('subject', '', 'from@example.com', ['to@example.com'])
+            email.encoding = 'iso-8859-1'
+            try:
+                message = email.message()
+                # The test should fail if the bug is present, expecting a UnicodeEncodeError.
+                self.assertIn('xn--p8s937b', message['Message-ID'])
+            except UnicodeEncodeError:
+                self.fail("Expected Message-ID to be encoded correctly, but UnicodeEncodeError was raised.")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/core/validators\.py|django/utils/encoding\.py|django/core/mail/message\.py|django/utils/html\.py|django/core/mail/utils\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11532
cat coverage.cover
git checkout a5308514fb4bc5086c9a16a8a24a945eeebb073c
git apply /root/pre_state.patch
