#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 6e9c5ee88fc948e05b4a7d9f82a8861ed2b0343d >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 6e9c5ee88fc948e05b4a7d9f82a8861ed2b0343d
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/contrib/sessions/backends/base.py b/django/contrib/sessions/backends/base.py
--- a/django/contrib/sessions/backends/base.py
+++ b/django/contrib/sessions/backends/base.py
@@ -108,6 +108,9 @@ def _hash(self, value):
 
     def encode(self, session_dict):
         "Return the given session dictionary serialized and encoded as a string."
+        # RemovedInDjango40Warning: DEFAULT_HASHING_ALGORITHM will be removed.
+        if settings.DEFAULT_HASHING_ALGORITHM == 'sha1':
+            return self._legacy_encode(session_dict)
         return signing.dumps(
             session_dict, salt=self.key_salt, serializer=self.serializer,
             compress=True,
@@ -121,6 +124,12 @@ def decode(self, session_data):
         except Exception:
             return self._legacy_decode(session_data)
 
+    def _legacy_encode(self, session_dict):
+        # RemovedInDjango40Warning.
+        serialized = self.serializer().dumps(session_dict)
+        hash = self._hash(serialized)
+        return base64.b64encode(hash.encode() + b':' + serialized).decode('ascii')
+
     def _legacy_decode(self, session_data):
         # RemovedInDjango40Warning: pre-Django 3.1 format will be invalid.
         encoded_data = base64.b64decode(session_data.encode('ascii'))

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13279.py
new file mode 100644
index e69de29..c5ff386 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13279.py
@@ -0,0 +1,23 @@
+from django.test import SimpleTestCase
+from django.conf import settings
+from django.contrib.sessions.backends.base import SessionBase
+from unittest.mock import patch
+
+class SessionDecodeTest(SimpleTestCase):
+    def setUp(self):
+        self.session_dict = {'key': 'value'}
+        self.session = SessionBase()
+        # Simulate encoding with a different algorithm
+        self.encoded_data = self.session.encode(self.session_dict)
+
+    def test_legacy_decode_with_sha1(self):
+        with patch.object(settings, 'DEFAULT_HASHING_ALGORITHM', 'sha1'):
+            # Attempt to decode the session data using the decode method
+            try:
+                decoded_data = self.session.decode(self.encoded_data)
+            except Exception as e:
+                # If an exception occurs, it indicates the bug is present
+                decoded_data = {}
+
+            # Assert that the decoded data matches the original session dictionary
+            self.assertEqual(decoded_data, self.session_dict, "Decoded data should match the original session dictionary")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/sessions/backends/base\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13279
cat coverage.cover
git checkout 6e9c5ee88fc948e05b4a7d9f82a8861ed2b0343d
git apply /root/pre_state.patch
