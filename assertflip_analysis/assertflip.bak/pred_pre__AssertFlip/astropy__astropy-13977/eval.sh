#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 5250b2442501e6c671c6b380536f1edb352602d1 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 5250b2442501e6c671c6b380536f1edb352602d1
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-13977.py
new file mode 100644
index e69de29..a14f3f0 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-13977.py
@@ -0,0 +1,34 @@
+import pytest
+import numpy as np
+import astropy.units as u
+import dataclasses
+
+@dataclasses.dataclass
+class DuckArray(np.lib.mixins.NDArrayOperatorsMixin):
+    ndarray: u.Quantity
+
+    @property
+    def unit(self) -> u.UnitBase:
+        return self.ndarray.unit
+
+    def __array_ufunc__(self, function, method, *inputs, **kwargs):
+        inputs = [inp.ndarray if isinstance(inp, DuckArray) else inp for inp in inputs]
+        for inp in inputs:
+            if isinstance(inp, np.ndarray):
+                result = inp.__array_ufunc__(function, method, *inputs, **kwargs)
+                if result is not NotImplemented:
+                    return DuckArray(result)
+        return NotImplemented
+
+def test_quantity_duckarray_incompatible_units():
+    # Create a DuckArray with 1 mm
+    duck_array = DuckArray(1 * u.mm)
+    # Create a Quantity with 1 m
+    quantity = 1 * u.m
+
+    # Perform the operation that triggers the bug
+    result = quantity + duck_array
+    # Check that the result is a DuckArray with the correct unit conversion
+    assert isinstance(result, DuckArray)
+    assert result.ndarray.unit == u.m
+    assert result.ndarray.value == 1.001  # 1 m + 0.001 m (1 mm in meters)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/units/quantity\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-13977.py
cat coverage.cover
git checkout 5250b2442501e6c671c6b380536f1edb352602d1
git apply /root/pre_state.patch
