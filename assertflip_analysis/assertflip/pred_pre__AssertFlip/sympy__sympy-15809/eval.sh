#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 28d913d3cead6c5646307ffa6540b21d65059dfd >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 28d913d3cead6c5646307ffa6540b21d65059dfd
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-15809.py
new file mode 100644
index e69de29..90185ea 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-15809.py
@@ -0,0 +1,8 @@
+from sympy import Min, Max, oo
+
+def test_min_max_no_arguments():
+    # Test Min() with no arguments
+    assert Min() == oo
+
+    # Test Max() with no arguments
+    assert Max() == -oo

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/functions/elementary/miscellaneous\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-15809.p
cat coverage.cover
git checkout 28d913d3cead6c5646307ffa6540b21d65059dfd
git apply /root/pre_state.patch
