#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD fbe850106b2e4b85f838219cb9e1df95fba6c164 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff fbe850106b2e4b85f838219cb9e1df95fba6c164
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16642.py
new file mode 100644
index e69de29..4771d3e 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16642.py
@@ -0,0 +1,28 @@
+from django.test import SimpleTestCase
+from django.http import FileResponse
+import os
+
+class MimeTypeGuessingTests(SimpleTestCase):
+    def setUp(self):
+        # Create mock files with .Z and .br extensions
+        self.z_file_path = 'test.html.Z'
+        self.br_file_path = 'test.html.br'
+        with open(self.z_file_path, 'wb') as f:
+            f.write(b'Test content for .Z file')
+        with open(self.br_file_path, 'wb') as f:
+            f.write(b'Test content for .br file')
+
+    def tearDown(self):
+        # Clean up the mock files
+        os.remove(self.z_file_path)
+        os.remove(self.br_file_path)
+
+    def test_mime_type_for_z_file(self):
+        with open(self.z_file_path, 'rb') as f:
+            response = FileResponse(f)
+            self.assertNotEqual(response['Content-Type'], 'text/html')
+
+    def test_mime_type_for_br_file(self):
+        with open(self.br_file_path, 'rb') as f:
+            response = FileResponse(f)
+            self.assertNotEqual(response['Content-Type'], 'text/html')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/http/response\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16642
cat coverage.cover
git checkout fbe850106b2e4b85f838219cb9e1df95fba6c164
git apply /root/pre_state.patch
