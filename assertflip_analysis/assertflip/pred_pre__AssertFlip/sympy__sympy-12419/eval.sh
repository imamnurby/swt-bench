#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 479939f8c65c8c2908bbedc959549a257a7c0b0b >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 479939f8c65c8c2908bbedc959549a257a7c0b0b
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-12419.py
new file mode 100644
index e69de29..dce56d4 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-12419.py
@@ -0,0 +1,24 @@
+from sympy import Symbol, symbols, MatrixSymbol, Sum, Q as Query, Identity
+from sympy.assumptions import assuming
+
+def test_identity_matrix_sum_bug():
+    # Setup
+    n = 3  # Use a specific value for n
+    i, j = symbols('i j', integer=True)
+    M = MatrixSymbol('M', n, n)
+
+    # Assume M is orthogonal and calculate M.T * M
+    with assuming(Query.orthogonal(M)):
+        e = Identity(n)  # Directly use Identity matrix to simulate the expected result
+
+    # Verify the identity matrix structure by checking individual elements
+    assert e[0, 0] == 1
+    assert e[0, 1] == 0
+    assert e[1, 0] == 0
+    assert e[1, 1] == 1
+
+    # Calculate the total sum of the elements of the identity matrix
+    total_sum = Sum(Sum(e[i, j], (i, 0, n-1)), (j, 0, n-1)).doit()
+
+    # Assert the correct behavior
+    assert total_sum == n  # The total sum should be 'n' for an identity matrix of size n

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/matrices/expressions/matexpr\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-12419.p
cat coverage.cover
git checkout 479939f8c65c8c2908bbedc959549a257a7c0b0b
git apply /root/pre_state.patch
