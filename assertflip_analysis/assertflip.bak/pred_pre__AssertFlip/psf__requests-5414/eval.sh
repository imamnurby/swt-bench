#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 39d0fdd9096f7dceccbc8f82e1eda7dd64717a8e >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 39d0fdd9096f7dceccbc8f82e1eda7dd64717a8e
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/test_coverup_psf__requests-5414.py
new file mode 100644
index e69de29..d4a6902 100644
--- /dev/null
+++ b/test_coverup_psf__requests-5414.py
@@ -0,0 +1,14 @@
+import pytest
+from requests.models import PreparedRequest
+from requests.exceptions import InvalidURL
+
+def test_invalid_url_instead_of_unicode_error():
+    # The URL that triggers the bug
+    malformed_url = "http://.example.com"
+    
+    # Prepare a request to trigger the URL preparation logic
+    req = PreparedRequest()
+    
+    # Expect an InvalidURL exception to be raised
+    with pytest.raises(InvalidURL, match="URL has an invalid label."):
+        req.prepare_url(malformed_url, None)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(requests/models\.py)' -m pytest --no-header -rA  -p no:cacheprovider test_coverup_psf__requests-5414.py
cat coverage.cover
git checkout 39d0fdd9096f7dceccbc8f82e1eda7dd64717a8e
git apply /root/pre_state.patch
