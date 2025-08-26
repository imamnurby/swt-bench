#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 51d37d1be95547059251076b3fadaa317750aab3 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 51d37d1be95547059251076b3fadaa317750aab3
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/xarray/tests/test_coverup_pydata__xarray-7233.py
new file mode 100644
index e69de29..095e299 100644
--- /dev/null
+++ b/xarray/tests/test_coverup_pydata__xarray-7233.py
@@ -0,0 +1,18 @@
+import numpy as np
+import xarray as xr
+import pytest
+
+def test_coarsen_construct_preserves_coordinates():
+    # Setup: Create a DataArray with a non-dimensional coordinate
+    da = xr.DataArray(np.arange(24), dims=["time"])
+    da = da.assign_coords(day=365 * da)
+    ds = da.to_dataset(name="T")
+
+    # Apply coarsen.construct
+    result = ds.coarsen(time=12).construct(time=("year", "month"))
+
+    # Assert that 'day' remains a coordinate
+    assert 'day' in result.coords
+
+    # Assert that 'day' is not demoted to a variable
+    assert 'day' not in result.variables

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(xarray/core/rolling\.py)' -m pytest --no-header -rA  -p no:cacheprovider xarray/tests/test_coverup_pydata__xarray-7233.py
cat coverage.cover
git checkout 51d37d1be95547059251076b3fadaa317750aab3
git apply /root/pre_state.patch
