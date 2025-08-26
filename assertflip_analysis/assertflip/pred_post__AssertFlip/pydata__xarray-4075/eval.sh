#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 19b088636eb7d3f65ab7a1046ac672e0689371d8 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 19b088636eb7d3f65ab7a1046ac672e0689371d8
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/xarray/core/weighted.py b/xarray/core/weighted.py
--- a/xarray/core/weighted.py
+++ b/xarray/core/weighted.py
@@ -142,7 +142,14 @@ def _sum_of_weights(
         # we need to mask data values that are nan; else the weights are wrong
         mask = da.notnull()
 
-        sum_of_weights = self._reduce(mask, self.weights, dim=dim, skipna=False)
+        # bool -> int, because ``xr.dot([True, True], [True, True])`` -> True
+        # (and not 2); GH4074
+        if self.weights.dtype == bool:
+            sum_of_weights = self._reduce(
+                mask, self.weights.astype(int), dim=dim, skipna=False
+            )
+        else:
+            sum_of_weights = self._reduce(mask, self.weights, dim=dim, skipna=False)
 
         # 0-weights are not valid
         valid_weights = sum_of_weights != 0.0

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/xarray/tests/test_coverup_pydata__xarray-4075.py
new file mode 100644
index e69de29..3332291 100644
--- /dev/null
+++ b/xarray/tests/test_coverup_pydata__xarray-4075.py
@@ -0,0 +1,16 @@
+import pytest
+import numpy as np
+import xarray as xr
+
+def test_weighted_mean_with_boolean_weights():
+    # Setup: Create a DataArray with sample data
+    data = xr.DataArray([1.0, 1.0, 1.0])
+    
+    # Setup: Create a DataArray for weights using boolean values
+    weights = xr.DataArray(np.array([True, True, False], dtype=bool))
+    
+    # Apply the weighted.mean() function
+    result = data.weighted(weights).mean()
+    
+    # Assert the correct behavior
+    assert result.item() == 1.0  # The expected correct behavior

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(xarray/core/weighted\.py)' -m pytest --no-header -rA  -p no:cacheprovider xarray/tests/test_coverup_pydata__xarray-4075.py
cat coverage.cover
git checkout 19b088636eb7d3f65ab7a1046ac672e0689371d8
git apply /root/pre_state.patch
