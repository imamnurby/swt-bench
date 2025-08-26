#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 9476425b9e34363c2d9ac38e9f04aa75ae54a775 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 9476425b9e34363c2d9ac38e9f04aa75ae54a775
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-13551.py
new file mode 100644
index e69de29..de89a90 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-13551.py
@@ -0,0 +1,13 @@
+from sympy import Product, simplify, symbols
+
+n, k = symbols('n k')
+
+def test_product_bug_exposure():
+    # Create the Product object with the expression and limits
+    p = Product(n + 1 / 2**k, (k, 0, n-1)).doit()
+    
+    # Simplify the result for comparison
+    result = simplify(p.subs(n, 2))
+    
+    # Assert the correct result to expose the bug
+    assert result == 15/2  # This is the correct expected result

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/concrete/products\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-13551.p
cat coverage.cover
git checkout 9476425b9e34363c2d9ac38e9f04aa75ae54a775
git apply /root/pre_state.patch
