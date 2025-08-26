#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d3b6aa6d8b997df115a53c001d00222a0f92f63a >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d3b6aa6d8b997df115a53c001d00222a0f92f63a
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/xarray/tests/test_coverup_pydata__xarray-4687.py
new file mode 100644
index e69de29..1ba3fcc 100644
--- /dev/null
+++ b/xarray/tests/test_coverup_pydata__xarray-4687.py
@@ -0,0 +1,18 @@
+import numpy as np
+import xarray as xr
+import pytest
+
+def test_xr_where_preserves_attributes():
+    # Create a DataArray with attributes and a specific dtype
+    data = xr.DataArray(np.ones([10, 10], dtype=np.int8))
+    data.attrs["attr_1"] = "test1"
+    data.attrs["attr_2"] = "test2"
+    
+    # Apply xr.where with a condition
+    result = xr.where(data == 1, 5, 0)
+    
+    # Check if the attributes are preserved
+    assert result.attrs == data.attrs, "Attributes should be preserved"
+    
+    # Check if the dtype is preserved
+    assert result.dtype == data.dtype, "Dtype should be preserved"

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(xarray/core/computation\.py)' -m pytest --no-header -rA  -p no:cacheprovider xarray/tests/test_coverup_pydata__xarray-4687.py
cat coverage.cover
git checkout d3b6aa6d8b997df115a53c001d00222a0f92f63a
git apply /root/pre_state.patch
