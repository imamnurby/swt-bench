#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 832c24fec1046eaa544a4cab4c69e3af3e651759 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 832c24fec1046eaa544a4cab4c69e3af3e651759
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/core/symbol.py b/sympy/core/symbol.py
--- a/sympy/core/symbol.py
+++ b/sympy/core/symbol.py
@@ -791,7 +791,7 @@ def literal(s):
         return tuple(result)
     else:
         for name in names:
-            result.append(symbols(name, **args))
+            result.append(symbols(name, cls=cls, **args))
 
         return type(names)(result)
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-23534.py
new file mode 100644
index e69de29..61388c1 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-23534.py
@@ -0,0 +1,14 @@
+from sympy import symbols, Function
+from sympy.core.function import UndefinedFunction
+
+def test_symbols_with_extra_parentheses():
+    # Using symbols with an extra layer of parentheses
+    q, u = symbols(('q:2', 'u:2'), cls=Function)
+    
+    # Check the type of the first element of q
+    assert isinstance(q[0], UndefinedFunction), \
+        "The type should be UndefinedFunction, but it is not due to the bug"
+
+    # Check the type of the first element of u
+    assert isinstance(u[0], UndefinedFunction), \
+        "The type should be UndefinedFunction, but it is not due to the bug"

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/core/symbol\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-23534.p
cat coverage.cover
git checkout 832c24fec1046eaa544a4cab4c69e3af3e651759
git apply /root/pre_state.patch
