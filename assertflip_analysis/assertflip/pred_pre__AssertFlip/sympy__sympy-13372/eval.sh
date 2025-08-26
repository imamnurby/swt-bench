#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 30379ea6e225e37833a764ac2da7b7fadf5fe374 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 30379ea6e225e37833a764ac2da7b7fadf5fe374
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-13372.py
new file mode 100644
index e69de29..6bcf72e 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-13372.py
@@ -0,0 +1,15 @@
+from sympy import symbols, Mul, Max
+
+def test_mul_max_evalf_unboundlocalerror():
+    # Define symbolic variables
+    x, y = symbols('x y')
+
+    # Test that Mul(x, Max(0, y), evaluate=False).evalf() does not raise an error
+    expr1 = Mul(x, Max(0, y), evaluate=False)
+    result1 = expr1.evalf()
+    assert result1 == x * Max(0, y)  # This should not raise an error
+
+    # Test that Mul(Max(0, y), x, evaluate=False).evalf() does not raise an error
+    expr2 = Mul(Max(0, y), x, evaluate=False)
+    result2 = expr2.evalf()
+    assert result2 == Max(0, y) * x  # This should not raise an error

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/core/evalf\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-13372.p
cat coverage.cover
git checkout 30379ea6e225e37833a764ac2da7b7fadf5fe374
git apply /root/pre_state.patch
