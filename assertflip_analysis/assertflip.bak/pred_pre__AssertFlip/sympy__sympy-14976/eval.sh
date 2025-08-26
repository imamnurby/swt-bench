#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 9cbea134220b0b951587e11b63e2c832c7246cbc >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 9cbea134220b0b951587e11b63e2c832c7246cbc
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-14976.py
new file mode 100644
index e69de29..82288e5 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-14976.py
@@ -0,0 +1,27 @@
+from sympy import Eq, S, RisingFactorial, lambdify, Float, rf
+from sympy.abc import x
+import inspect
+import mpmath
+
+def test_lambdify_mpmath_rational_precision():
+    # Define the symbolic equation with a rational number
+    eqn = Eq(rf(18, x), 77 + S(1)/3)
+    
+    # Create a lambda function using lambdify with mpmath
+    f = lambdify(x, eqn.lhs - eqn.rhs, 'mpmath')
+    
+    # Get the source code of the generated lambda function
+    source_code = inspect.getsource(f)
+    
+    # Assert that the source code does not contain the unevaluated rational number
+    assert '232/3' not in source_code  # The rational should be evaluated to a float
+    
+    # Solve the equation numerically with high precision
+    x0 = mpmath.nsolve(eqn, Float('1.5', 64), prec=64)
+    
+    # Evaluate the result with high precision
+    result = rf(18, x0).evalf(64)
+    
+    # Assert that the result matches the expected high precision result
+    expected_result = 77 + S(1)/3
+    assert result == expected_result.evalf(64)  # The result should match the expected high precision result

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/printing/pycode\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-14976.p
cat coverage.cover
git checkout 9cbea134220b0b951587e11b63e2c832c7246cbc
git apply /root/pre_state.patch
