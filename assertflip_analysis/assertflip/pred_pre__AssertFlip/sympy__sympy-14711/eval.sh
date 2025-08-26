#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD c6753448b5c34f95e250105d76709fe4d349ca1f >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff c6753448b5c34f95e250105d76709fe4d349ca1f
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-14711.py
new file mode 100644
index e69de29..c70d326 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-14711.py
@@ -0,0 +1,6 @@
+from sympy.physics.vector import ReferenceFrame
+
+def test_vector_add_zero_multiplication():
+    N = ReferenceFrame('N')
+    result = sum([N.x, (0 * N.x)])
+    assert result == N.x

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/physics/vector/vector\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-14711.p
cat coverage.cover
git checkout c6753448b5c34f95e250105d76709fe4d349ca1f
git apply /root/pre_state.patch
