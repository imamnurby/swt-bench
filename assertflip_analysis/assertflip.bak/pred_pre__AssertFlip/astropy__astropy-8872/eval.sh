#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD b750a0e6ee76fb6b8a099a4d16ec51977be46bf6 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff b750a0e6ee76fb6b8a099a4d16ec51977be46bf6
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-8872.py
new file mode 100644
index e69de29..b8a94f5 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-8872.py
@@ -0,0 +1,17 @@
+import pytest
+import numpy as np
+from astropy import units as u
+from astropy.units import Quantity
+
+def test_quantity_float16_dtype_bug():
+    # Create a Quantity using np.float16
+    value = np.float16(1)
+    quantity = Quantity(value, unit=u.km)
+
+    # Retrieve the dtype of the resulting Quantity
+    dtype = quantity.dtype
+
+    # Assert that the dtype is float16, which is the expected correct behavior
+    assert dtype == np.float16, "BUG: np.float16 should not be upgraded to np.float64"
+
+    # Cleanup steps if necessary (not needed in this case as no state pollution occurs)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/units/quantity\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-8872.py
cat coverage.cover
git checkout b750a0e6ee76fb6b8a099a4d16ec51977be46bf6
git apply /root/pre_state.patch
