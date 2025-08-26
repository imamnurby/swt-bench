#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 851dadeb0338403e5021c3fbe80cbc9127ee672d >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 851dadeb0338403e5021c3fbe80cbc9127ee672d
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/xarray/tests/test_coverup_pydata__xarray-6461.py
new file mode 100644
index e69de29..339f6ec 100644
--- /dev/null
+++ b/xarray/tests/test_coverup_pydata__xarray-6461.py
@@ -0,0 +1,22 @@
+import pytest
+import xarray as xr
+
+def test_where_with_scalar_and_keep_attrs():
+    # Setup: Create a condition DataArray
+    cond = xr.DataArray([True, False, True], dims=["dim"])
+    
+    # Scalars for x and y
+    x = 1
+    y = 0
+    
+    # Test: Expect no error when keep_attrs=True
+    try:
+        # This should not raise an error when the bug is fixed
+        result = xr.where(cond, x, y, keep_attrs=True)
+        # Check if the result is as expected
+        expected = xr.DataArray([1, 0, 1], dims=["dim"])
+        xr.testing.assert_equal(result, expected)
+    except IndexError:
+        pytest.fail("IndexError was raised, indicating the bug is present")
+
+    # Cleanup: No specific cleanup required

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(xarray/core/computation\.py)' -m pytest --no-header -rA  -p no:cacheprovider xarray/tests/test_coverup_pydata__xarray-6461.py
cat coverage.cover
git checkout 851dadeb0338403e5021c3fbe80cbc9127ee672d
git apply /root/pre_state.patch
