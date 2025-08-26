#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 3f8c8c2377cb8e0daaf8073e8d03ac7d87580813 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 3f8c8c2377cb8e0daaf8073e8d03ac7d87580813
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-22080.py
new file mode 100644
index e69de29..a751ef6 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-22080.py
@@ -0,0 +1,26 @@
+from sympy import Mod, lambdify, symbols
+
+def test_lambdify_mod_bug():
+    # Define symbols
+    x, y = symbols('x y')
+    
+    # Define the expression with a multiplier
+    expr = 2 * Mod(x, y)
+    
+    # Create lambdified functions
+    f = lambdify([x, y], expr)  # Default modules
+    g = lambdify([x, y], expr, modules=[])  # With modules=[]
+    
+    # Evaluate both functions with the same arguments
+    result_f = f(3, 7)
+    result_g = g(3, 7)
+    
+    # Assert the expected correct behavior
+    assert result_f == 2 * (3 % 7)  # Correct behavior
+    
+    # Assert the expected correct behavior for g
+    assert result_g == 2 * (3 % 7)  # Correct behavior
+
+    # Inspect the source code of the generated function to confirm the transformation
+    source_g = g.__code__.co_code
+    assert b'\x16\x00' not in source_g  # Ensure the incorrect transformation is not present

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/printing/codeprinter\.py|sympy/printing/precedence\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-22080.p
cat coverage.cover
git checkout 3f8c8c2377cb8e0daaf8073e8d03ac7d87580813
git apply /root/pre_state.patch
