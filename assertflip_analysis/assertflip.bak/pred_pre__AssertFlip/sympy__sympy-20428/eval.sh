#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD c0e85160406f9bf2bcaa2992138587668a1cd0bc >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff c0e85160406f9bf2bcaa2992138587668a1cd0bc
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-20428.py
new file mode 100644
index e69de29..5018faa 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-20428.py
@@ -0,0 +1,20 @@
+from sympy import symbols, sympify, Poly
+from sympy.utilities.pytest import raises
+
+def test_clear_denoms_bug():
+    x = symbols("x")
+    expr = sympify("-117968192370600*18**(1/3)/(217603955769048*(24201 + 253*sqrt(9165))**(1/3) + 2273005839412*sqrt(9165)*(24201 + 253*sqrt(9165))**(1/3)) - 15720318185*2**(2/3)*3**(1/3)*(24201 + 253*sqrt(9165))**(2/3)/(217603955769048*(24201 + 253*sqrt(9165))**(1/3) + 2273005839412*sqrt(9165)*(24201 + 253*sqrt(9165))**(1/3)) + 15720318185*12**(1/3)*(24201 + 253*sqrt(9165))**(2/3)/(217603955769048*(24201 + 253*sqrt(9165))**(1/3) + 2273005839412*sqrt(9165)*(24201 + 253*sqrt(9165))**(1/3)) + 117968192370600*2**(1/3)*3**(2/3)/(217603955769048*(24201 + 253*sqrt(9165))**(1/3) + 2273005839412*sqrt(9165)*(24201 + 253*sqrt(9165))**(1/3))")
+    f = Poly(expr, x)
+    coeff, bad_poly = f.clear_denoms()
+
+    # Assert that bad_poly prints as zero
+    assert str(bad_poly) == "Poly(0, x, domain='EX')"
+
+    # Correct behavior: bad_poly should be zero
+    assert bad_poly.is_zero is True
+
+    # Assert that bad_poly.as_expr() evaluates to 0
+    assert bad_poly.as_expr() == 0
+
+    # Assert that the expression evaluates to zero
+    assert bad_poly.as_expr().is_zero is True

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/polys/domains/expressiondomain\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-20428.p
cat coverage.cover
git checkout c0e85160406f9bf2bcaa2992138587668a1cd0bc
git apply /root/pre_state.patch
