#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD c935e1d106743efd5bf0705fbeedbd18fadff4dc >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff c935e1d106743efd5bf0705fbeedbd18fadff4dc
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-13852.py
new file mode 100644
index e69de29..f1e9029 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-13852.py
@@ -0,0 +1,16 @@
+from sympy import symbols, polylog, expand_func, log
+
+def test_expand_func_polylog_bug():
+    # Setup symbolic variable
+    z = symbols('z')
+
+    # Expand polylog(1, z) and check for the presence of exp_polar(-I*pi)
+    expanded_expr = expand_func(polylog(1, z))
+    
+    # Assert that the expanded expression is equal to the expected correct form
+    # The expected correct form should be -log(1 - z) without exp_polar
+    expected_expr = -log(1 - z)
+    
+    # Check if the expanded expression is equal to the expected correct form
+    assert expanded_expr == expected_expr  # The test should fail if the bug is present
+

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/functions/special/zeta_functions\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-13852.p
cat coverage.cover
git checkout c935e1d106743efd5bf0705fbeedbd18fadff4dc
git apply /root/pre_state.patch
