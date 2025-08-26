#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 67e3c956083d0128a621f65ee86a7dacd4f9f19f >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 67e3c956083d0128a621f65ee86a7dacd4f9f19f
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-13647.py
new file mode 100644
index e69de29..83b66b5 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-13647.py
@@ -0,0 +1,24 @@
+from sympy import eye, ones
+from sympy.utilities.pytest import raises
+
+def test_matrix_col_insert_bug():
+    # Create a 6x6 identity matrix
+    M = eye(6)
+    # Create a 6x2 matrix filled with the value 2
+    V = 2 * ones(6, 2)
+    # Insert the 6x2 matrix into the identity matrix at the 3rd column index
+    result = M.col_insert(3, V)
+    
+    # Assert the resulting matrix has the expected dimensions (6x8)
+    assert result.shape == (6, 8)
+    
+    # Assert that the identity matrix is shifted correctly
+    expected_correct_matrix = [
+        [1, 0, 0, 2, 2, 0, 0, 0],
+        [0, 1, 0, 2, 2, 0, 0, 0],
+        [0, 0, 1, 2, 2, 0, 0, 0],
+        [0, 0, 0, 2, 2, 1, 0, 0],
+        [0, 0, 0, 2, 2, 0, 1, 0],
+        [0, 0, 0, 2, 2, 0, 0, 1]
+    ]
+    assert result.tolist() == expected_correct_matrix

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/matrices/common\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-13647.p
cat coverage.cover
git checkout 67e3c956083d0128a621f65ee86a7dacd4f9f19f
git apply /root/pre_state.patch
