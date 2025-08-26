#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD b1cb676cf92dd1a48365b731979833375b188bf2 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff b1cb676cf92dd1a48365b731979833375b188bf2
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-24562.py
new file mode 100644
index e69de29..559ae36 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-24562.py
@@ -0,0 +1,16 @@
+from sympy import Rational
+
+def test_rational_string_input_bug():
+    # Test with string inputs
+    r1 = Rational('0.5', '100')
+    # Test with float inputs
+    r2 = Rational(0.5, 100)
+    
+    # Assert that the correct behavior should occur
+    assert str(Rational('0.5', '100')) == '1/200'
+    
+    # Assert that the correct behavior occurs with float inputs
+    assert str(Rational(0.5, 100)) == '1/200'
+    
+    # Assert that the two results are equal, which should be the correct behavior
+    assert str(Rational('0.5', '100')) == str(Rational(0.5, 100))

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/core/numbers\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-24562.p
cat coverage.cover
git checkout b1cb676cf92dd1a48365b731979833375b188bf2
git apply /root/pre_state.patch
