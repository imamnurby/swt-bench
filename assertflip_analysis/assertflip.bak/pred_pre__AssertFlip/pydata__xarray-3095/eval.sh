#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 1757dffac2fa493d7b9a074b84cf8c830a706688 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 1757dffac2fa493d7b9a074b84cf8c830a706688
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/xarray/tests/test_coverup_pydata__xarray-3095.py
new file mode 100644
index e69de29..e034927 100644
--- /dev/null
+++ b/xarray/tests/test_coverup_pydata__xarray-3095.py
@@ -0,0 +1,21 @@
+import pytest
+import xarray as xr
+
+def test_deep_copy_unicode_index_cast_to_object():
+    # Create a Dataset with Unicode index variables
+    ds = xr.Dataset(
+        coords={'x': ['foo'], 'y': ('x', ['bar'])},
+        data_vars={'z': ('x', ['baz'])}
+    )
+    
+    # Perform a deep copy of the dataset
+    ds_copy = ds.copy(deep=True)
+    
+    # Assert that the dtype of the 'x' coordinate in the copied dataset is '<U3'
+    # This is the expected correct behavior
+    assert ds_copy.coords['x'].dtype == '<U3', "Expected dtype '<U3' for 'x' coordinate"
+    
+    # Assert that the 'y' coordinate and 'z' data variable retain their original dtype '<U3'
+    assert ds_copy.coords['y'].dtype == '<U3', "Expected dtype '<U3' for 'y' coordinate"
+    assert ds_copy['z'].dtype == '<U3', "Expected dtype '<U3' for 'z' data variable"
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(xarray/core/indexing\.py|xarray/core/variable\.py)' -m pytest --no-header -rA  -p no:cacheprovider xarray/tests/test_coverup_pydata__xarray-3095.py
cat coverage.cover
git checkout 1757dffac2fa493d7b9a074b84cf8c830a706688
git apply /root/pre_state.patch
