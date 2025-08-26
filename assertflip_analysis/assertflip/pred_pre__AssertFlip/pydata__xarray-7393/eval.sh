#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 41fef6f1352be994cd90056d47440fe9aa4c068f >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 41fef6f1352be994cd90056d47440fe9aa4c068f
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/xarray/tests/test_coverup_pydata__xarray-7393.py
new file mode 100644
index e69de29..5b3ff84 100644
--- /dev/null
+++ b/xarray/tests/test_coverup_pydata__xarray-7393.py
@@ -0,0 +1,16 @@
+import pytest
+import xarray as xr
+import numpy as np
+
+def test_stack_int32_to_int64_bug():
+    # Create a dataset with a coordinate of dtype int32
+    ds = xr.Dataset(coords={'a': np.array([0], dtype='i4')})
+    
+    # Perform the stack operation to create a MultiIndex
+    stacked_ds = ds.stack(b=('a',))
+    
+    # Assert that the dtype of the original coordinate is int32
+    assert ds['a'].values.dtype == np.int32
+    
+    # Assert that the dtype of the coordinate after stacking remains int32
+    assert stacked_ds['a'].values.dtype == np.int32

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(xarray/core/indexing\.py)' -m pytest --no-header -rA  -p no:cacheprovider xarray/tests/test_coverup_pydata__xarray-7393.py
cat coverage.cover
git checkout 41fef6f1352be994cd90056d47440fe9aa4c068f
git apply /root/pre_state.patch
