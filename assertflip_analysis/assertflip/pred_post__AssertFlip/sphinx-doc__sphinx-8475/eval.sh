#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 3ea1ec84cc610f7a9f4f6b354e264565254923ff >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 3ea1ec84cc610f7a9f4f6b354e264565254923ff
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/sphinx/builders/linkcheck.py b/sphinx/builders/linkcheck.py
--- a/sphinx/builders/linkcheck.py
+++ b/sphinx/builders/linkcheck.py
@@ -20,7 +20,7 @@
 
 from docutils import nodes
 from docutils.nodes import Node
-from requests.exceptions import HTTPError
+from requests.exceptions import HTTPError, TooManyRedirects
 
 from sphinx.application import Sphinx
 from sphinx.builders import Builder
@@ -172,7 +172,7 @@ def check_uri() -> Tuple[str, str, int]:
                                                  config=self.app.config, auth=auth_info,
                                                  **kwargs)
                         response.raise_for_status()
-                    except HTTPError:
+                    except (HTTPError, TooManyRedirects):
                         # retry with GET request if that fails, some servers
                         # don't like HEAD requests.
                         response = requests.get(req_url, stream=True, config=self.app.config,

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-8475.py
new file mode 100644
index e69de29..a1f4222 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-8475.py
@@ -0,0 +1,66 @@
+import pytest
+from unittest.mock import patch, Mock
+from requests.exceptions import TooManyRedirects
+from sphinx.builders.linkcheck import CheckExternalLinksBuilder
+from sphinx.application import Sphinx
+import queue
+
+def test_too_many_redirects_fallback():
+    # Mock the URL to simulate a TooManyRedirects behavior
+    test_url = "https://idr.openmicroscopy.org/webclient/?show=well-119093"
+
+    # Create a mock Sphinx app
+    mock_app = Mock(spec=Sphinx)
+    mock_app.config = Mock()
+    mock_app.config.linkcheck_timeout = None
+    mock_app.config.linkcheck_anchors = False
+    mock_app.config.linkcheck_retries = 1
+    mock_app.config.linkcheck_request_headers = {}
+    mock_app.srcdir = '/mock/srcdir'
+    mock_app.confdir = '/mock/confdir'
+    mock_app.outdir = '/mock/outdir'
+    mock_app.doctreedir = '/mock/doctreedir'
+    mock_app.events = Mock()  # Add missing attribute
+    mock_app.tags = Mock()  # Add missing attribute
+
+    # Create an instance of the CheckExternalLinksBuilder with the mock app
+    builder = CheckExternalLinksBuilder(mock_app)
+
+    # Initialize the queues as queue.Queue() objects
+    builder.wqueue = queue.Queue()
+    builder.rqueue = queue.Queue()
+
+    # Initialize necessary attributes
+    builder.good = set()
+    builder.broken = {}
+    builder.redirected = {}
+    builder.anchors_ignore = []
+    builder.to_ignore = []
+    builder.auth = []  # Initialize auth to avoid AttributeError
+
+    # Mock requests.head to raise TooManyRedirects
+    with patch('sphinx.util.requests.head') as mock_head:
+        mock_head.side_effect = TooManyRedirects
+
+        # Mock requests.get to return a successful response
+        with patch('sphinx.util.requests.get') as mock_get:
+            mock_response = Mock()
+            mock_response.raise_for_status.return_value = None
+            mock_response.url = test_url
+            mock_get.return_value = mock_response
+
+            # Simulate the check_thread method's behavior
+            builder.wqueue.put((test_url, 'docname', 1))
+            builder.wqueue.put((None, None, None))
+
+            # Run the check_thread method
+            builder.check_thread()
+
+            # Retrieve the result from the rqueue
+            result = builder.rqueue.get()
+
+            # Assert that the status is 'working' when the bug is fixed
+            assert result[3] == 'working', "The URL should be reported as working when the bug is fixed."
+
+            # Assert that the GET request was made
+            assert mock_get.called, "The GET request should be made when the bug is fixed."

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/builders/linkcheck\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-8475.py
cat coverage.cover
git checkout 3ea1ec84cc610f7a9f4f6b354e264565254923ff
git apply /root/pre_state.patch
