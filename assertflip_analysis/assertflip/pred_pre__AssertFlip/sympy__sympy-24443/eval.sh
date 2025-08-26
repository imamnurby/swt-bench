#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 809c53c077485ca48a206cee78340389cb83b7f1 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 809c53c077485ca48a206cee78340389cb83b7f1
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-24443.py
new file mode 100644
index e69de29..98ee1b3 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-24443.py
@@ -0,0 +1,22 @@
+from sympy.combinatorics import PermutationGroup, Permutation
+from sympy.combinatorics.homomorphisms import _check_homomorphism
+from sympy.combinatorics.named_groups import DihedralGroup
+
+def test_check_homomorphism_with_inverted_generators():
+    # Create a Dihedral group D3
+    D3 = DihedralGroup(3)
+    
+    # Define generators and their inverses
+    gens = D3.generators
+    inverses = [g**-1 for g in gens]
+    
+    # Create a homomorphism mapping each generator to itself
+    images = {g: g for g in gens}
+    
+    # Include inverses in the images
+    images.update({g**-1: g**-1 for g in gens})
+    
+    # Call _check_homomorphism and assert it returns True for valid homomorphisms
+    assert _check_homomorphism(D3, D3, images) is True
+
+# The test will fail if the bug is present by returning False for valid homomorphisms.

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/combinatorics/homomorphisms\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-24443.p
cat coverage.cover
git checkout 809c53c077485ca48a206cee78340389cb83b7f1
git apply /root/pre_state.patch
