#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 1d3327b8e90a186df6972991963a5ae87053259d >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 1d3327b8e90a186df6972991963a5ae87053259d
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-17139.py
new file mode 100644
index e69de29..024c049 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-17139.py
@@ -0,0 +1,13 @@
+from sympy import Symbol, cos, I
+from sympy.simplify import simplify
+
+def test_simplify_cos_complex_exponent():
+    x = Symbol('x')
+    expr = cos(x)**I
+    try:
+        result = simplify(expr)
+    except TypeError:
+        assert False, "TypeError was raised"
+    else:
+        assert result is not None, "Simplification did not return a result"
+

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/simplify/fu\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-17139.p
cat coverage.cover
git checkout 1d3327b8e90a186df6972991963a5ae87053259d
git apply /root/pre_state.patch
