#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD aa9780761ad8c3c0f68beeef3a0ce5caac9e100b >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff aa9780761ad8c3c0f68beeef3a0ce5caac9e100b
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-12489.py
new file mode 100644
index e69de29..371a327 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-12489.py
@@ -0,0 +1,9 @@
+from sympy.combinatorics.permutations import Permutation
+
+class SubclassedPermutation(Permutation):
+    pass
+
+def test_subclassing_permutation():
+    instance = SubclassedPermutation([0, 1, 2])
+    assert not isinstance(instance, Permutation)  # The instance should not be of type Permutation
+    assert isinstance(instance, SubclassedPermutation)  # The instance should be of type SubclassedPermutation

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/combinatorics/permutations\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-12489.p
cat coverage.cover
git checkout aa9780761ad8c3c0f68beeef3a0ce5caac9e100b
git apply /root/pre_state.patch
