#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD b16c7d12ccbc7b2d20364b89fb44285bcbfede54 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff b16c7d12ccbc7b2d20364b89fb44285bcbfede54
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-14995.py
new file mode 100644
index e69de29..b24fd15 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-14995.py
@@ -0,0 +1,20 @@
+import pytest
+import numpy as np
+from astropy.nddata import NDDataRef
+
+def test_nddataref_mask_propagation_bug():
+    # Setup: Create an array and a mask
+    array = np.array([[0, 1, 0], [1, 0, 1], [0, 1, 0]])
+    mask = np.array([[0, 1, 64], [8, 0, 1], [2, 1, 0]])
+
+    # Create NDDataRef instances, one with a mask and one without
+    nref_nomask = NDDataRef(array)
+    nref_mask = NDDataRef(array, mask=mask)
+
+    # Test: multiply mask by constant (mask * no mask)
+    result_mask = nref_mask.multiply(1., handle_mask=np.bitwise_or).mask
+    assert np.array_equal(result_mask, mask), "Mask should be propagated correctly when multiplied by a constant."
+
+    # Test: multiply mask by no mask (mask * no mask)
+    result_mask = nref_mask.multiply(nref_nomask, handle_mask=np.bitwise_or).mask
+    assert np.array_equal(result_mask, mask), "Mask should be propagated correctly when multiplied by an unmasked NDDataRef."

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/nddata/mixins/ndarithmetic\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-14995.py
cat coverage.cover
git checkout b16c7d12ccbc7b2d20364b89fb44285bcbfede54
git apply /root/pre_state.patch
