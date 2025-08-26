#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 624217179aaf8d094e6ff75b7493ad1ee47599b0 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 624217179aaf8d094e6ff75b7493ad1ee47599b0
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/core/mod.py b/sympy/core/mod.py
--- a/sympy/core/mod.py
+++ b/sympy/core/mod.py
@@ -40,6 +40,7 @@ def eval(cls, p, q):
         from sympy.core.mul import Mul
         from sympy.core.singleton import S
         from sympy.core.exprtools import gcd_terms
+        from sympy.polys.polyerrors import PolynomialError
         from sympy.polys.polytools import gcd
 
         def doit(p, q):
@@ -166,10 +167,13 @@ def doit(p, q):
         # XXX other possibilities?
 
         # extract gcd; any further simplification should be done by the user
-        G = gcd(p, q)
-        if G != 1:
-            p, q = [
-                gcd_terms(i/G, clear=False, fraction=False) for i in (p, q)]
+        try:
+            G = gcd(p, q)
+            if G != 1:
+                p, q = [gcd_terms(i/G, clear=False, fraction=False)
+                        for i in (p, q)]
+        except PolynomialError:  # issue 21373
+            G = S.One
         pwas, qwas = p, q
 
         # simplify terms

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-21379.py
new file mode 100644
index e69de29..ab1f297 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-21379.py
@@ -0,0 +1,23 @@
+from sympy import symbols, exp, sinh, Piecewise
+from sympy.core.cache import clear_cache
+from sympy.polys.polyerrors import PolynomialError
+from sympy.testing.pytest import raises
+
+def test_subs_polynomial_error_with_real_symbols():
+    from sympy import exp, sinh, Piecewise, symbols
+
+    # Clear cache to ensure the bug is triggered
+    from sympy.core.cache import clear_cache
+    clear_cache()
+
+    # Define real symbols
+    x, y, z = symbols('x y z', real=True)
+
+    # Define the expression as described in the issue ticket
+    expr = exp(sinh(Piecewise((x, y > x), (y, True)) / z))
+
+    # Assert that no PolynomialError is raised when subs is called
+    try:
+        expr.subs({1: 1.0})
+    except PolynomialError:
+        assert False, "PolynomialError was raised unexpectedly"

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/core/mod\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-21379.p
cat coverage.cover
git checkout 624217179aaf8d094e6ff75b7493ad1ee47599b0
git apply /root/pre_state.patch
