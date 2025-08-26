#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 22623bd8c265b78b161542663ee980738441c307 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 22623bd8c265b78b161542663ee980738441c307
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/test_coverup_psf__requests-1142.py
new file mode 100644
index e69de29..4f41d71 100644
--- /dev/null
+++ b/test_coverup_psf__requests-1142.py
@@ -0,0 +1,34 @@
+import pytest
+from requests import Session
+from requests.models import Request, PreparedRequest
+
+def test_get_request_does_not_include_content_length_header(monkeypatch):
+    # Mock the adapter's send method to capture the prepared request
+    class MockAdapter:
+        def send(self, request, **kwargs):
+            # Assert that the 'Content-Length' header is NOT present, which is the correct behavior
+            assert 'Content-Length' not in request.headers
+            # Return a mock response object
+            class MockResponse:
+                status_code = 503  # Simulate the server returning a 503 error due to 'Content-Length'
+                headers = request.headers
+                cookies = {}
+            return MockResponse()
+
+    # Mock the get_adapter method to return the mock adapter
+    def mock_get_adapter(self, url):
+        return MockAdapter()
+
+    # Use monkeypatch to replace the get_adapter method with the mock_get_adapter
+    monkeypatch.setattr(Session, 'get_adapter', mock_get_adapter)
+
+    # Create a session and send a GET request
+    session = Session()
+    response = session.get('http://example.com')
+
+    # Assert that the response status code is 503, indicating the server rejected the request due to 'Content-Length'
+    assert response.status_code == 503
+
+    # Assert that 'Content-Length' is NOT present in the headers, which is the correct behavior
+    assert 'Content-Length' not in response.headers
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(requests/models\.py)' -m pytest --no-header -rA  -p no:cacheprovider test_coverup_psf__requests-1142.py
cat coverage.cover
git checkout 22623bd8c265b78b161542663ee980738441c307
git apply /root/pre_state.patch
