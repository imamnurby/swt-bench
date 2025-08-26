#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a5e6a101869e027e7930e694f8b1cfb082603453 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a5e6a101869e027e7930e694f8b1cfb082603453
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-13757.py
new file mode 100644
index e69de29..d8974f0 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-13757.py
@@ -0,0 +1,9 @@
+from sympy import symbols, Poly
+
+x = symbols('x')
+
+def test_multiply_expression_by_poly():
+    # Multiplying a symbolic expression by a Poly with the expression on the left
+    result = x * Poly(x)
+    # Correct behavior should be a Poly object representing x**2
+    assert str(result) == "Poly(x**2, x, domain='ZZ')"

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/polys/polytools\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-13757.p
cat coverage.cover
git checkout a5e6a101869e027e7930e694f8b1cfb082603453
git apply /root/pre_state.patch
