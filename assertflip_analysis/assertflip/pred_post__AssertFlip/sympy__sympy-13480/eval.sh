#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD f57fe3f4b3f2cab225749e1b3b38ae1bf80b62f0 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff f57fe3f4b3f2cab225749e1b3b38ae1bf80b62f0
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/functions/elementary/hyperbolic.py b/sympy/functions/elementary/hyperbolic.py
--- a/sympy/functions/elementary/hyperbolic.py
+++ b/sympy/functions/elementary/hyperbolic.py
@@ -587,7 +587,7 @@ def eval(cls, arg):
                 x, m = _peeloff_ipi(arg)
                 if m:
                     cothm = coth(m)
-                    if cotm is S.ComplexInfinity:
+                    if cothm is S.ComplexInfinity:
                         return coth(x)
                     else: # cothm == 0
                         return tanh(x)

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-13480.py
new file mode 100644
index e69de29..809388c 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-13480.py
@@ -0,0 +1,11 @@
+from sympy import Symbol, coth, log, tan
+from sympy.utilities.pytest import raises
+
+def test_coth_log_tan_subs_nameerror():
+    x = Symbol('x')
+    e = coth(log(tan(x)))
+    problematic_values = [2, 3, 5, 6, 8, 9, 11, 12, 13, 15, 18]
+
+    for value in problematic_values:
+        with raises(NameError, match="name 'cotm' is not defined"):
+            e.subs(x, value)

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/functions/elementary/hyperbolic\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-13480.p
cat coverage.cover
git checkout f57fe3f4b3f2cab225749e1b3b38ae1bf80b62f0
git apply /root/pre_state.patch
