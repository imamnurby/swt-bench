#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 701441853569d370506514083b995d11f9a130bd >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 701441853569d370506514083b995d11f9a130bd
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-15976.py
new file mode 100644
index e69de29..eb6d7f7 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-15976.py
@@ -0,0 +1,16 @@
+from sympy import symbols
+from sympy.printing.mathml import mathml
+
+def test_mathml_symbol_with_number():
+    # Define symbols with names ending in numbers
+    x2, y, z = symbols('x2 y z')
+    
+    # Create an expression using these symbols
+    expr = x2 * z + x2**3
+    
+    # Convert the expression to MathML format
+    mathml_output = mathml(expr, printer='presentation')
+    
+    # Check the MathML output to confirm the presence of the symbol 'x2'
+    # The test should pass only when 'x2' is correctly visible in the MathML output
+    assert '<mi>x2</mi>' in mathml_output

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/printing/mathml\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-15976.p
cat coverage.cover
git checkout 701441853569d370506514083b995d11f9a130bd
git apply /root/pre_state.patch
