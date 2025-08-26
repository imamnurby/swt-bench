#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 3ff4717b6aef6086e78f01cdfa06f64ae23aed7e >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 3ff4717b6aef6086e78f01cdfa06f64ae23aed7e
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-22714.py
new file mode 100644
index e69de29..52bbda3 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-22714.py
@@ -0,0 +1,11 @@
+import sympy as sp
+
+def test_point2d_evaluate_false_bug():
+    try:
+        with sp.evaluate(False):
+            # Attempt to create a Point2D object with evaluate=False
+            sp.S('Point2D(Integer(1),Integer(2))')
+    except ValueError as e:
+        assert False, f"Unexpected ValueError raised: {e}"
+    else:
+        assert True

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/geometry/point\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-22714.p
cat coverage.cover
git checkout 3ff4717b6aef6086e78f01cdfa06f64ae23aed7e
git apply /root/pre_state.patch
