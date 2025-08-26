#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 5e17a90c19f7eecfa10c1ab872648ae7e2131323 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 5e17a90c19f7eecfa10c1ab872648ae7e2131323
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-15599.py
new file mode 100644
index e69de29..9f89073 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-15599.py
@@ -0,0 +1,11 @@
+from sympy import Symbol, Mod
+
+def test_mod_simplification_bug():
+    # Define a symbolic integer variable
+    i = Symbol('i', integer=True)
+    
+    # Construct the expression Mod(3*i, 2)
+    expr = Mod(3*i, 2)
+    
+    # Assert that the expression simplifies correctly
+    assert expr == Mod(i, 2)

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/core/mod\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-15599.p
cat coverage.cover
git checkout 5e17a90c19f7eecfa10c1ab872648ae7e2131323
git apply /root/pre_state.patch
