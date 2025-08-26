#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD cc183652bf6e1273e985e1c4b3cba79c896c1193 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff cc183652bf6e1273e985e1c4b3cba79c896c1193
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/xarray/tests/test_coverup_pydata__xarray-6721.py
new file mode 100644
index e69de29..26ead68 100644
--- /dev/null
+++ b/xarray/tests/test_coverup_pydata__xarray-6721.py
@@ -0,0 +1,16 @@
+import pytest
+import xarray as xr
+from unittest.mock import patch
+
+def test_chunksizes_triggers_data_load():
+    # Setup: Open the dataset using the provided URL
+    url = "https://ncsa.osn.xsede.org/Pangeo/pangeo-forge/swot_adac/FESOM/surf/fma.zarr"
+    ds = xr.open_dataset(url, engine='zarr')
+
+    # Mock the data loading function to track if it is called
+    with patch('xarray.core.variable._as_array_or_item') as mock_as_array_or_item:
+        # Access the chunksizes attribute
+        chunksizes = ds.chunksizes
+
+        # Assert that the mocked data loading function is not called, indicating the bug is fixed
+        assert mock_as_array_or_item.call_count == 0  # Correct behavior: no data load should occur

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(xarray/core/common\.py)' -m pytest --no-header -rA  -p no:cacheprovider xarray/tests/test_coverup_pydata__xarray-6721.py
cat coverage.cover
git checkout cc183652bf6e1273e985e1c4b3cba79c896c1193
git apply /root/pre_state.patch
