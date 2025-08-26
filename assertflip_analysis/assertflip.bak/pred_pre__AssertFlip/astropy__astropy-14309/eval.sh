#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD cdb66059a2feb44ee49021874605ba90801f9986 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff cdb66059a2feb44ee49021874605ba90801f9986
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-14309.py
new file mode 100644
index e69de29..97d24b7 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-14309.py
@@ -0,0 +1,14 @@
+import pytest
+from astropy.io.registry import identify_format
+from astropy.table import Table
+
+def test_identify_format_with_empty_args():
+    # Prepare a non-FITS file path and empty args
+    non_fits_filepath = "bububu.ecsv"
+    empty_args = []
+
+    # Call identify_format with parameters that lead to is_fits being called with empty args
+    result = identify_format("write", Table, non_fits_filepath, None, empty_args, {})
+    
+    # Assert that the function handles empty args gracefully and does not raise IndexError
+    assert result is not None

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/io/fits/connect\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-14309.py
cat coverage.cover
git checkout cdb66059a2feb44ee49021874605ba90801f9986
git apply /root/pre_state.patch
