#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD fdc707f73a65a429935c01532cd3970d3355eab6 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff fdc707f73a65a429935c01532cd3970d3355eab6
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/utilities/lambdify.py b/sympy/utilities/lambdify.py
--- a/sympy/utilities/lambdify.py
+++ b/sympy/utilities/lambdify.py
@@ -956,9 +956,9 @@ def _recursive_to_string(doprint, arg):
         return doprint(arg)
     elif iterable(arg):
         if isinstance(arg, list):
-            left, right = "[]"
+            left, right = "[", "]"
         elif isinstance(arg, tuple):
-            left, right = "()"
+            left, right = "(", ",)"
         else:
             raise NotImplementedError("unhandled type: %s, %s" % (type(arg), arg))
         return left +', '.join(_recursive_to_string(doprint, e) for e in arg) + right

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-23262.py
new file mode 100644
index e69de29..f4f1e49 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-23262.py
@@ -0,0 +1,12 @@
+from sympy import lambdify
+import inspect
+
+def test_single_element_tuple_bug():
+    # Create a lambda function with a single-element tuple
+    func = lambdify([], tuple([1]))
+    
+    # Get the source code of the generated function
+    source_code = inspect.getsource(func)
+    
+    # Assert that the generated code correctly includes the comma
+    assert "return (1,)" in source_code  # Correct behavior: the tuple should include a comma

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/utilities/lambdify\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-23262.p
cat coverage.cover
git checkout fdc707f73a65a429935c01532cd3970d3355eab6
git apply /root/pre_state.patch
