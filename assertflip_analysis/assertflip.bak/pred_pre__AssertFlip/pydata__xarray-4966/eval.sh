#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 37522e991a32ee3c0ad1a5ff8afe8e3eb1885550 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 37522e991a32ee3c0ad1a5ff8afe8e3eb1885550
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/xarray/tests/test_coverup_pydata__xarray-4966.py
new file mode 100644
index e69de29..bbc0d88 100644
--- /dev/null
+++ b/xarray/tests/test_coverup_pydata__xarray-4966.py
@@ -0,0 +1,25 @@
+import pytest
+import xarray as xr
+import numpy as np
+
+def test_unsigned_false_handling():
+    # Dataset URL with the issue
+    url = "https://observations.ipsl.fr/thredds/dodsC/EUREC4A/PRODUCTS/testdata/netcdf_testfiles/test_NC_BYTE_neg.nc"
+    
+    # Open dataset with netcdf4 engine
+    ds_netcdf4 = xr.open_dataset(url, engine="netcdf4")
+    # Open dataset with pydap engine
+    ds_pydap = xr.open_dataset(url, engine="pydap")
+    
+    # Extract the 'test' coordinate values
+    test_values_netcdf4 = ds_netcdf4.coords['test'].values
+    test_values_pydap = ds_pydap.coords['test'].values
+    
+    # Assert that the values are the same once the bug is fixed
+    # Specifically, check that values interpreted as negative in netcdf4 are correctly handled in pydap
+    assert np.array_equal(test_values_netcdf4, test_values_pydap), \
+        "BUG: pydap engine incorrectly handles _Unsigned=False, leading to different values compared to netcdf4"
+    
+    # Cleanup
+    ds_netcdf4.close()
+    ds_pydap.close()

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(xarray/coding/variables\.py)' -m pytest --no-header -rA  -p no:cacheprovider xarray/tests/test_coverup_pydata__xarray-4966.py
cat coverage.cover
git checkout 37522e991a32ee3c0ad1a5ff8afe8e3eb1885550
git apply /root/pre_state.patch
