#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 3dff1b98a78f28c953ae2140b69356b8391e399c >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 3dff1b98a78f28c953ae2140b69356b8391e399c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/polys/polytools.py b/sympy/polys/polytools.py
--- a/sympy/polys/polytools.py
+++ b/sympy/polys/polytools.py
@@ -2,7 +2,8 @@
 
 from __future__ import print_function, division
 
-from functools import wraps
+from functools import wraps, reduce
+from operator import mul
 
 from sympy.core import (
     S, Basic, Expr, I, Integer, Add, Mul, Dummy, Tuple
@@ -5905,10 +5906,7 @@ def _symbolic_factor_list(expr, opt, method):
         if arg.is_Number:
             coeff *= arg
             continue
-        if arg.is_Mul:
-            args.extend(arg.args)
-            continue
-        if arg.is_Pow:
+        elif arg.is_Pow:
             base, exp = arg.args
             if base.is_Number and exp.is_Number:
                 coeff *= arg
@@ -5949,6 +5947,9 @@ def _symbolic_factor_list(expr, opt, method):
                         other.append((f, k))
 
                 factors.append((_factors_product(other), exp))
+    if method == 'sqf':
+        factors = [(reduce(mul, (f for f, _ in factors if _ == k)), k)
+                   for k in set(i for _, i in factors)]
 
     return coeff, factors
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-18698.py
new file mode 100644
index e69de29..54ce687 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-18698.py
@@ -0,0 +1,17 @@
+from sympy.testing.pytest import raises
+from sympy import sqf_list
+from sympy.abc import x
+
+def test_sqf_list_incorrect_multiplicity():
+    # Test case from the issue ticket
+    result = sqf_list((x**2 + 1) * (x - 1)**2 * (x - 2)**3 * (x - 3)**3)
+    
+    # Assert that the output is a tuple
+    assert isinstance(result, tuple)
+    
+    # Assert that the first element is the correct coefficient
+    assert result[0] == 1
+    
+    # Assert that the list of factors contains the expected factors with their correct multiplicities
+    # The expected correct behavior is one factor of multiplicity 3
+    assert result[1] == [(x**2 + 1, 1), (x - 1, 2), (x - 2, 3), (x - 3, 3)]

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/polys/polytools\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-18698.p
cat coverage.cover
git checkout 3dff1b98a78f28c953ae2140b69356b8391e399c
git apply /root/pre_state.patch
