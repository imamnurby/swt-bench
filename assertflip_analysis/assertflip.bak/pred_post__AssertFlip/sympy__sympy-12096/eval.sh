#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d7c3045115693e887bcd03599b7ca4650ac5f2cb >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d7c3045115693e887bcd03599b7ca4650ac5f2cb
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/core/function.py b/sympy/core/function.py
--- a/sympy/core/function.py
+++ b/sympy/core/function.py
@@ -507,7 +507,7 @@ def _eval_evalf(self, prec):
             func = getattr(mpmath, fname)
         except (AttributeError, KeyError):
             try:
-                return Float(self._imp_(*self.args), prec)
+                return Float(self._imp_(*[i.evalf(prec) for i in self.args]), prec)
             except (AttributeError, TypeError, ValueError):
                 return
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-12096.py
new file mode 100644
index e69de29..a3a1afd 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-12096.py
@@ -0,0 +1,16 @@
+from sympy.utilities.lambdify import implemented_function
+from sympy import Symbol
+
+def test_evalf_composition_bug():
+    # Define implemented functions
+    f = implemented_function('f', lambda x: x ** 2)
+    g = implemented_function('g', lambda x: 2 * x)
+    
+    # Create a symbol for evaluation
+    x = Symbol('x')
+    
+    # Evaluate the composition f(g(2))
+    result = f(g(2)).evalf()
+    
+    # Assert that the result is correctly evaluated
+    assert result == 16.0

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/core/function\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-12096.p
cat coverage.cover
git checkout d7c3045115693e887bcd03599b7ca4650ac5f2cb
git apply /root/pre_state.patch
