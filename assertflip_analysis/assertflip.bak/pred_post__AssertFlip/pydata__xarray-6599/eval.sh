#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 6bb2b855498b5c68d7cca8cceb710365d58e6048 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 6bb2b855498b5c68d7cca8cceb710365d58e6048
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/xarray/core/computation.py b/xarray/core/computation.py
--- a/xarray/core/computation.py
+++ b/xarray/core/computation.py
@@ -1933,7 +1933,8 @@ def _ensure_numeric(data: T_Xarray) -> T_Xarray:
     from .dataset import Dataset
 
     def to_floatable(x: DataArray) -> DataArray:
-        if x.dtype.kind in "mM":
+        if x.dtype.kind == "M":
+            # datetimes
             return x.copy(
                 data=datetime_to_numeric(
                     x.data,
@@ -1941,6 +1942,9 @@ def to_floatable(x: DataArray) -> DataArray:
                     datetime_unit="ns",
                 ),
             )
+        elif x.dtype.kind == "m":
+            # timedeltas
+            return x.astype(float)
         return x
 
     if isinstance(data, Dataset):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/xarray/tests/test_coverup_pydata__xarray-6599.py
new file mode 100644
index e69de29..c6ae981 100644
--- /dev/null
+++ b/xarray/tests/test_coverup_pydata__xarray-6599.py
@@ -0,0 +1,39 @@
+import pytest
+import xarray as xr
+import numpy as np
+
+def test_polyval_with_timedelta64_coordinates():
+    # Setup: Create azimuth_time with timedelta64 coordinates
+    values = np.array(
+        [
+            "2021-04-01T05:25:19.000000000",
+            "2021-04-01T05:25:29.000000000",
+            "2021-04-01T05:25:39.000000000",
+            "2021-04-01T05:25:49.000000000",
+            "2021-04-01T05:25:59.000000000",
+            "2021-04-01T05:26:09.000000000",
+        ],
+        dtype="datetime64[ns]",
+    )
+    azimuth_time = xr.DataArray(
+        values, name="azimuth_time", coords={"azimuth_time": values - values[0]}
+    )
+
+    # Setup: Create polyfit_coefficients
+    polyfit_coefficients = xr.DataArray(
+        [
+            [2.33333335e-43, 1.62499999e-43, 2.79166678e-43],
+            [-1.15316667e-30, 1.49518518e-31, 9.08833333e-31],
+            [-2.50272583e-18, -1.23851062e-18, -2.99098229e-18],
+            [5.83965193e-06, -1.53321770e-07, -4.84640242e-06],
+            [4.44739216e06, 1.45053974e06, 5.29960857e06],
+        ],
+        dims=("degree", "axis"),
+        coords={"axis": [0, 1, 2], "degree": [4, 3, 2, 1, 0]},
+    )
+
+    # Call the polyval function
+    result = xr.polyval(azimuth_time, polyfit_coefficients)
+
+    # Assert the shape is correct, indicating the bug is fixed
+    assert result.shape == (6, 3)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(xarray/core/computation\.py)' -m pytest --no-header -rA  -p no:cacheprovider xarray/tests/test_coverup_pydata__xarray-6599.py
cat coverage.cover
git checkout 6bb2b855498b5c68d7cca8cceb710365d58e6048
git apply /root/pre_state.patch
