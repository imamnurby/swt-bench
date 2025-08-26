#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD c807dfe7569692cad24f02a08477b70c1679a4dd >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff c807dfe7569692cad24f02a08477b70c1679a4dd
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-12481.py
new file mode 100644
index e69de29..9bcc853 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-12481.py
@@ -0,0 +1,8 @@
+from sympy.combinatorics.permutations import Permutation
+
+def test_permutation_non_disjoint_cycles_bug():
+    # Test for non-disjoint cycles in Permutation constructor
+    # The expected behavior is to construct the identity permutation
+
+    p = Permutation([[0, 1], [0, 1]])
+    assert p.array_form == [0, 1]  # This should construct an identity permutation

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/combinatorics/permutations\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-12481.p
cat coverage.cover
git checkout c807dfe7569692cad24f02a08477b70c1679a4dd
git apply /root/pre_state.patch
