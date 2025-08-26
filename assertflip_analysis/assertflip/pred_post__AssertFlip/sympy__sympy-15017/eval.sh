#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 6810dee426943c1a2fe85b5002dd0d4cf2246a05 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 6810dee426943c1a2fe85b5002dd0d4cf2246a05
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/tensor/array/dense_ndim_array.py b/sympy/tensor/array/dense_ndim_array.py
--- a/sympy/tensor/array/dense_ndim_array.py
+++ b/sympy/tensor/array/dense_ndim_array.py
@@ -149,7 +149,7 @@ def _new(cls, iterable, shape, **kwargs):
         self._shape = shape
         self._array = list(flat_list)
         self._rank = len(shape)
-        self._loop_size = functools.reduce(lambda x,y: x*y, shape) if shape else 0
+        self._loop_size = functools.reduce(lambda x,y: x*y, shape, 1)
         return self
 
     def __setitem__(self, index, value):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-15017.py
new file mode 100644
index e69de29..693d136 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-15017.py
@@ -0,0 +1,8 @@
+from sympy import Array
+
+def test_len_rank_0_array():
+    # Create a rank-0 array (scalar) using sympy.Array
+    a = Array(3)
+    
+    # Assert that len(a) returns 1, which is the correct behavior
+    assert len(a) == 1

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/tensor/array/dense_ndim_array\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-15017.p
cat coverage.cover
git checkout 6810dee426943c1a2fe85b5002dd0d4cf2246a05
git apply /root/pre_state.patch
