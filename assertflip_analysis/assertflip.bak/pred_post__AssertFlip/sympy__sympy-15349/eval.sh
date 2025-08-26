#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 768da1c6f6ec907524b8ebbf6bf818c92b56101b >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 768da1c6f6ec907524b8ebbf6bf818c92b56101b
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/algebras/quaternion.py b/sympy/algebras/quaternion.py
--- a/sympy/algebras/quaternion.py
+++ b/sympy/algebras/quaternion.py
@@ -529,7 +529,7 @@ def to_rotation_matrix(self, v=None):
 
         m10 = 2*s*(q.b*q.c + q.d*q.a)
         m11 = 1 - 2*s*(q.b**2 + q.d**2)
-        m12 = 2*s*(q.c*q.d + q.b*q.a)
+        m12 = 2*s*(q.c*q.d - q.b*q.a)
 
         m20 = 2*s*(q.b*q.d - q.c*q.a)
         m21 = 2*s*(q.c*q.d + q.b*q.a)

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-15349.py
new file mode 100644
index e69de29..7b42996 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-15349.py
@@ -0,0 +1,23 @@
+from sympy.algebras.quaternion import Quaternion
+from sympy import symbols, cos, sin, trigsimp, Matrix
+
+def test_quaternion_to_rotation_matrix_bug():
+    # Define a symbolic variable
+    x = symbols('x')
+    
+    # Create a quaternion with known parameters
+    q = Quaternion(cos(x/2), sin(x/2), 0, 0)
+    
+    # Generate the rotation matrix using to_rotation_matrix()
+    rotation_matrix = trigsimp(q.to_rotation_matrix())
+    
+    # Expected correct matrix after the bug is fixed
+    expected_matrix = Matrix([
+        [1, 0, 0],
+        [0, cos(x), -sin(x)],  # Corrected: [0, cos(x), -sin(x)]
+        [0, sin(x), cos(x)]    # Corrected: [0, sin(x), cos(x)]
+    ])
+    
+    # Assert that the matrix matches the expected correct form
+    assert rotation_matrix == expected_matrix, "The rotation matrix does not match the expected correct form."
+

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/algebras/quaternion\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-15349.p
cat coverage.cover
git checkout 768da1c6f6ec907524b8ebbf6bf818c92b56101b
git apply /root/pre_state.patch
