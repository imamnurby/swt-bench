#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD f5e965947af2410ded92cfad987aaf45262ea434 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff f5e965947af2410ded92cfad987aaf45262ea434
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-17655.py
new file mode 100644
index e69de29..31b5323 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-17655.py
@@ -0,0 +1,17 @@
+from sympy import geometry as ge, sympify
+
+def test_point_multiplication_order():
+    # Create two Point objects
+    point1 = ge.Point(0, 0)
+    point2 = ge.Point(1, 1)
+    
+    # Convert a number to a SymPy object
+    factor = sympify(2.0)
+    
+    # Perform the addition in both orders
+    result1 = point1 + point2 * factor
+    assert result1 == ge.Point(2, 2)  # This should work without issues
+    
+    # Check that the second order works correctly
+    result2 = point1 + factor * point2
+    assert result2 == ge.Point(2, 2)  # This should also work without issues

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/geometry/point\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-17655.p
cat coverage.cover
git checkout f5e965947af2410ded92cfad987aaf45262ea434
git apply /root/pre_state.patch
