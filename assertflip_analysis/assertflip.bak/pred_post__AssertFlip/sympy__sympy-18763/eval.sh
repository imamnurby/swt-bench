#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 70381f282f2d9d039da860e391fe51649df2779d >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 70381f282f2d9d039da860e391fe51649df2779d
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/printing/latex.py b/sympy/printing/latex.py
--- a/sympy/printing/latex.py
+++ b/sympy/printing/latex.py
@@ -703,7 +703,7 @@ def _print_Subs(self, subs):
         latex_new = (self._print(e) for e in new)
         latex_subs = r'\\ '.join(
             e[0] + '=' + e[1] for e in zip(latex_old, latex_new))
-        return r'\left. %s \right|_{\substack{ %s }}' % (latex_expr,
+        return r'\left. \left(%s\right) \right|_{\substack{ %s }}' % (latex_expr,
                                                          latex_subs)
 
     def _print_Integral(self, expr):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-18763.py
new file mode 100644
index e69de29..693a821 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-18763.py
@@ -0,0 +1,15 @@
+from sympy import Subs, latex
+from sympy.abc import x, y
+
+def test_incorrect_parenthesizing_of_subs():
+    # Create a Subs object with the expression -x + y, substituting x with 1
+    subs_expr = Subs(-x + y, (x,), (1,))
+    
+    # Multiply the Subs object by 3
+    expr = 3 * subs_expr
+    
+    # Convert the expression to a LaTeX string
+    latex_str = latex(expr)
+    
+    # Assert that the LaTeX string matches the correct format
+    assert latex_str == r'3 \left. \left(- x + y\right) \right|_{\substack{ x=1 }}'

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/printing/latex\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-18763.p
cat coverage.cover
git checkout 70381f282f2d9d039da860e391fe51649df2779d
git apply /root/pre_state.patch
