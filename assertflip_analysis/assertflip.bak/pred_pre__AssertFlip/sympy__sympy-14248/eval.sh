#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 9986b38181cdd556a3f3411e553864f11912244e >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 9986b38181cdd556a3f3411e553864f11912244e
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-14248.py
new file mode 100644
index e69de29..84b12b3 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-14248.py
@@ -0,0 +1,24 @@
+from sympy import MatrixSymbol
+from sympy.printing.str import StrPrinter
+from sympy.printing.pretty.pretty import PrettyPrinter
+from sympy.printing.latex import LatexPrinter
+
+def test_matrixsymbol_difference_printing():
+    A = MatrixSymbol('A', 2, 2)
+    B = MatrixSymbol('B', 2, 2)
+    expr = A - A*B - B
+
+    # Test the string representation
+    str_printer = StrPrinter()
+    str_output = str_printer.doprint(expr)
+    assert str_output == "A - A*B - B"
+
+    # Test pretty print
+    pretty_printer = PrettyPrinter()
+    pretty_output = pretty_printer.doprint(expr)
+    assert pretty_output == "A - A⋅B - B"
+
+    # Test for LaTeX output
+    latex_printer = LatexPrinter()
+    latex_output = latex_printer.doprint(expr)
+    assert latex_output == "A - A B - B"

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/printing/pretty/pretty\.py|sympy/printing/str\.py|sympy/printing/latex\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-14248.p
cat coverage.cover
git checkout 9986b38181cdd556a3f3411e553864f11912244e
git apply /root/pre_state.patch
