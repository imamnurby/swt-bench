#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d9b18c518d64d0ebe8e35a98c2fb519938b9b151 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d9b18c518d64d0ebe8e35a98c2fb519938b9b151
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-21847.py
new file mode 100644
index e69de29..744023b 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-21847.py
@@ -0,0 +1,22 @@
+from sympy import symbols
+from sympy.polys.monomials import itermonomials
+from sympy.polys.orderings import monomial_key
+
+def test_itermonomials_min_degrees_bug():
+    # Define symbolic variables
+    x1, x2, x3 = symbols('x1 x2 x3')
+    states = [x1, x2, x3]
+    max_degrees = 3
+    min_degrees = 3
+
+    # Generate monomials with specified min and max degrees
+    monomials = sorted(itermonomials(states, max_degrees, min_degrees=min_degrees), 
+                       key=monomial_key('grlex', states))
+
+    # Expected monomials should include combinations like x1*x2**2, x2*x3**2, etc.
+    expected_monomials = {x1**3, x2**3, x3**3, x1*x2**2, x1*x3**2, x2*x1**2, x2*x3**2, x3*x1**2, x3*x2**2, x1*x2*x3}
+
+    # Assert that the result includes all expected monomials
+    assert set(monomials) == expected_monomials, f"BUG: Incorrect monomials generated: {set(monomials)}"
+
+# This test will fail if the bug is present, as it checks for the presence of all expected monomials.

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/polys/monomials\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-21847.p
cat coverage.cover
git checkout d9b18c518d64d0ebe8e35a98c2fb519938b9b151
git apply /root/pre_state.patch
