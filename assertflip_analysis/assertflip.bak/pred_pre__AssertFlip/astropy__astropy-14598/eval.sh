#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 80c3854a5f4f4a6ab86c03d9db7854767fcd83c1 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 80c3854a5f4f4a6ab86c03d9db7854767fcd83c1
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-14598.py
new file mode 100644
index e69de29..771f2f6 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-14598.py
@@ -0,0 +1,11 @@
+import pytest
+from astropy.io import fits
+
+def test_double_single_quote_handling():
+    # Test for the bug where double single-quotes are incorrectly transformed
+    for n in range(60, 70):
+        card1 = fits.Card('CONFIG', "x" * n + "''")
+        card2 = fits.Card.fromstring(str(card1))
+        
+        # Assert that the values are equal, which is the expected correct behavior
+        assert card1.value == card2.value

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/io/fits/card\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-14598.py
cat coverage.cover
git checkout 80c3854a5f4f4a6ab86c03d9db7854767fcd83c1
git apply /root/pre_state.patch
