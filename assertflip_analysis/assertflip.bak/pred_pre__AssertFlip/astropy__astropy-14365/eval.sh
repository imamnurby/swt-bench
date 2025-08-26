#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 7269fa3e33e8d02485a647da91a5a2a60a06af61 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 7269fa3e33e8d02485a647da91a5a2a60a06af61
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-14365.py
new file mode 100644
index e69de29..04f84ff 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-14365.py
@@ -0,0 +1,9 @@
+import pytest
+from astropy.io.ascii.qdp import _line_type
+
+def test_line_type_lowercase_command():
+    # Test with a lowercase command that should be recognized
+    line = "read serr 1 2"
+    
+    # The test should pass if the line is correctly recognized and does not raise an error
+    assert _line_type(line) is not None

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/io/ascii/qdp\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-14365.py
cat coverage.cover
git checkout 7269fa3e33e8d02485a647da91a5a2a60a06af61
git apply /root/pre_state.patch
