#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a3475b3f9ac662cd425157dd3bdb93ad7111c090 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a3475b3f9ac662cd425157dd3bdb93ad7111c090
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-22456.py
new file mode 100644
index e69de29..3df4c2e 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-22456.py
@@ -0,0 +1,15 @@
+from sympy.codegen.ast import String
+
+def test_string_argument_invariance_bug():
+    # Create a String instance with a sample string
+    original_string = String('example')
+
+    # Extract the args from the String instance
+    args = original_string.args
+
+    # Attempt to reconstruct the String object using expr.func and expr.args
+    # This should hold true when the bug is fixed
+    reconstructed_string = original_string.func(*args)
+
+    # Check if the reconstructed string is equal to the original string
+    assert reconstructed_string == original_string, "Reconstructed string does not match the original"

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/codegen/ast\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-22456.p
cat coverage.cover
git checkout a3475b3f9ac662cd425157dd3bdb93ad7111c090
git apply /root/pre_state.patch
