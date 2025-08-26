#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD b506169ad727ee39cb3d60c8b3ff5e315d443d8e >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff b506169ad727ee39cb3d60c8b3ff5e315d443d8e
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-15875.py
new file mode 100644
index e69de29..3e1aeda 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-15875.py
@@ -0,0 +1,11 @@
+from sympy import I, simplify
+
+def test_is_zero_bug():
+    # Define the complex expression
+    e = -2*I + (1 + I)**2
+    
+    # Check the is_zero property
+    result = e.is_zero
+    
+    # Assert that the result is None, which is the correct behavior
+    assert result is None

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/core/add\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-15875.p
cat coverage.cover
git checkout b506169ad727ee39cb3d60c8b3ff5e315d443d8e
git apply /root/pre_state.patch
