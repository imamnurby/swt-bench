#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 3aa75c8d00a4a2d4acf10d80f76b937cadb666b7 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 3aa75c8d00a4a2d4acf10d80f76b937cadb666b7
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/xarray/tests/test_coverup_pydata__xarray-7229.py
new file mode 100644
index e69de29..773df51 100644
--- /dev/null
+++ b/xarray/tests/test_coverup_pydata__xarray-7229.py
@@ -0,0 +1,15 @@
+import xarray as xr
+import pytest
+
+def test_xr_where_overwrites_coordinate_attrs():
+    # Load the sample dataset
+    ds = xr.tutorial.load_dataset("air_temperature")
+    
+    # Perform the xr.where operation with keep_attrs=True
+    result = xr.where(True, ds.air, ds.air, keep_attrs=True)
+    
+    # Retrieve the attributes of the 'time' coordinate
+    result_time_attrs = result['time'].attrs
+    
+    # Assert that the attrs are correct (i.e., they should not match the variable attributes)
+    assert result_time_attrs == {'standard_name': 'time', 'long_name': 'Time'}

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(xarray/core/computation\.py)' -m pytest --no-header -rA  -p no:cacheprovider xarray/tests/test_coverup_pydata__xarray-7229.py
cat coverage.cover
git checkout 3aa75c8d00a4a2d4acf10d80f76b937cadb666b7
git apply /root/pre_state.patch
