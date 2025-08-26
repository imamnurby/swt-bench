#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 1659712001810f5fc563a443949f8e3bb38af4bd >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 1659712001810f5fc563a443949f8e3bb38af4bd
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-13877.py
new file mode 100644
index e69de29..0288f01 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-13877.py
@@ -0,0 +1,14 @@
+from sympy import Matrix, Symbol, det, nan
+from sympy.utilities.pytest import raises
+
+def test_determinant_nan_and_typeerror():
+    a = Symbol('a')
+    f = lambda n: det(Matrix([[i + a*j for i in range(n)] for j in range(n)]))
+    
+    # Test for 5x5 matrix
+    result_5x5 = f(5)
+    assert result_5x5 != nan  # The result should not be NaN when the bug is fixed
+    
+    # Test for 6x6 matrix
+    with raises(TypeError, match="Invalid NaN comparison"):
+        f(6)  # This should not raise a TypeError when the bug is fixed

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/utilities/randtest\.py|sympy/matrices/matrices\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-13877.p
cat coverage.cover
git checkout 1659712001810f5fc563a443949f8e3bb38af4bd
git apply /root/pre_state.patch
