#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 25fbcce5b1a4c7e3956e6062930f4a44ce95a632 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 25fbcce5b1a4c7e3956e6062930f4a44ce95a632
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-19495.py
new file mode 100644
index e69de29..2e58736 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-19495.py
@@ -0,0 +1,24 @@
+from sympy import Symbol, S, Rational, Interval, asin, pi
+from sympy.sets import ConditionSet, Contains, ImageSet
+from sympy.core import Lambda
+
+def test_conditionset_imageset_subs_bug():
+    # Recreate the issue with a ConditionSet containing an ImageSet
+    x = Symbol('x')
+    y = Symbol('y')
+    n = Symbol('n')
+    
+    # Create an ImageSet
+    img_set = ImageSet(Lambda(n, 2 * n * pi + asin(y)), S.Integers)
+    
+    # Create a ConditionSet with the ImageSet
+    cond_set = ConditionSet(x, Contains(y, Interval(-1, 1)), img_set)
+    
+    # Perform substitution
+    result = cond_set.subs(y, Rational(1, 3))
+    
+    # Expected correct behavior
+    expected_correct_result = ImageSet(Lambda(n, 2 * n * pi + asin(Rational(1, 3))), S.Integers)
+    
+    # Assert that the correct behavior occurs
+    assert result == expected_correct_result

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/sets/conditionset\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-19495.p
cat coverage.cover
git checkout 25fbcce5b1a4c7e3956e6062930f4a44ce95a632
git apply /root/pre_state.patch
