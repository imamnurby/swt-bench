#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD ba80d1e493f21431b4bf729b3e0452cd47eb9566 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff ba80d1e493f21431b4bf729b3e0452cd47eb9566
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-18199.py
new file mode 100644
index e69de29..a2f01ab 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-18199.py
@@ -0,0 +1,8 @@
+from sympy.utilities.pytest import XFAIL
+from sympy.ntheory.residue_ntheory import nthroot_mod
+
+def test_nthroot_mod_missing_zero_root():
+    # Test input where a % p == 0
+    roots = nthroot_mod(17*17, 5, 17, all_roots=True)
+    # 0 should be in the list of roots but is currently missing due to the bug
+    assert 0 not in roots  # This assertion should fail because the bug is present

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/ntheory/residue_ntheory\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-18199.p
cat coverage.cover
git checkout ba80d1e493f21431b4bf729b3e0452cd47eb9566
git apply /root/pre_state.patch
