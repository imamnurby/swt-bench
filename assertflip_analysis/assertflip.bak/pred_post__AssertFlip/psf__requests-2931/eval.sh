#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 5f7a3a74aab1625c2bb65f643197ee885e3da576 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 5f7a3a74aab1625c2bb65f643197ee885e3da576
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install .
git apply -v - <<'EOF_114329324912'
diff --git a/requests/models.py b/requests/models.py
--- a/requests/models.py
+++ b/requests/models.py
@@ -81,7 +81,7 @@ def _encode_params(data):
         """
 
         if isinstance(data, (str, bytes)):
-            return to_native_string(data)
+            return data
         elif hasattr(data, 'read'):
             return data
         elif hasattr(data, '__iter__'):
@@ -385,6 +385,9 @@ def prepare_url(self, url, params):
             if isinstance(fragment, str):
                 fragment = fragment.encode('utf-8')
 
+        if isinstance(params, (str, bytes)):
+            params = to_native_string(params)
+
         enc_params = self._encode_params(params)
         if enc_params:
             if query:

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/test_coverup_psf__requests-2931.py
new file mode 100644
index e69de29..3241c60 100644
--- /dev/null
+++ b/test_coverup_psf__requests-2931.py
@@ -0,0 +1,14 @@
+import pytest
+import requests
+
+def test_put_request_with_binary_payload():
+    # Setup: Define the URL and the binary payload
+    url = "http://httpbin.org/put"
+    binary_payload = u"ööö".encode("utf-8")
+
+    # Action: Send a PUT request with the binary payload
+    # We expect this to succeed without raising an exception
+    response = requests.put(url, data=binary_payload)
+
+    # Assert: Check that the request was successful
+    assert response.status_code == 200

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(requests/models\.py)' -m pytest --no-header -rA  -p no:cacheprovider test_coverup_psf__requests-2931.py
cat coverage.cover
git checkout 5f7a3a74aab1625c2bb65f643197ee885e3da576
git apply /root/pre_state.patch
