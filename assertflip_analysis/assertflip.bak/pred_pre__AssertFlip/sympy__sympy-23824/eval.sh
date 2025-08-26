#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 39de9a2698ad4bb90681c0fdb70b30a78233145f >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 39de9a2698ad4bb90681c0fdb70b30a78233145f
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-23824.py
new file mode 100644
index e69de29..528ee69 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-23824.py
@@ -0,0 +1,15 @@
+from sympy.physics.hep.gamma_matrices import GammaMatrix as G, kahane_simplify, LorentzIndex
+from sympy.tensor.tensor import tensor_indices
+
+def test_kahane_leading_gamma_matrix_bug():
+    mu, nu, rho, sigma = tensor_indices("mu, nu, rho, sigma", LorentzIndex)
+    
+    # Test case 1: Correct behavior
+    t1 = G(mu)*G(-mu)*G(rho)*G(sigma)
+    r1 = kahane_simplify(t1)
+    assert r1.equals(4*G(rho)*G(sigma)), "Test case 1 failed: Order of gamma matrices is incorrect"
+
+    # Test case 2: Correct behavior expected
+    t2 = G(rho)*G(sigma)*G(mu)*G(-mu)
+    r2 = kahane_simplify(t2)
+    assert r2.equals(4*G(rho)*G(sigma)), "Test case 2 failed: Order of gamma matrices is incorrect"

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/physics/hep/gamma_matrices\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-23824.p
cat coverage.cover
git checkout 39de9a2698ad4bb90681c0fdb70b30a78233145f
git apply /root/pre_state.patch
