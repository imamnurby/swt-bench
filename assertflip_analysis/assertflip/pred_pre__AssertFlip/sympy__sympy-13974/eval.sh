#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 84c125972ad535b2dfb245f8d311d347b45e5b8a >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 84c125972ad535b2dfb245f8d311d347b45e5b8a
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-13974.py
new file mode 100644
index e69de29..651a28a 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-13974.py
@@ -0,0 +1,23 @@
+from sympy import Symbol
+from sympy.physics.quantum import TensorProduct as tp, tensor_product_simp as tps
+from sympy.physics.paulialgebra import Pauli
+
+def test_tensor_product_power_simplification():
+    # Define non-commutative symbols and Pauli matrices
+    a = Symbol('a', commutative=False)
+    
+    # Create tensor products
+    t1 = tp(1, 1) * tp(1, 1)
+    t2 = tp(1, Pauli(3)) * tp(1, Pauli(3))
+    
+    # Apply tensor_product_simp and expand(tensorproduct=True)
+    t1_simp = tps(t1)
+    t1_expanded = t1.expand(tensorproduct=True)
+    t2_simp = tps(t2)
+    t2_expanded = t2.expand(tensorproduct=True)
+    
+    # Assert that the output is simplified correctly
+    assert str(t1_simp) == "1x1"  # Correct behavior expected after bug fix
+    assert str(t1_expanded) == "1x1"  # Correct behavior expected after bug fix
+    assert str(t2_simp) == "1x1"  # Correct behavior expected after bug fix
+    assert str(t2_expanded) == "1x1"  # Correct behavior expected after bug fix

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/physics/quantum/tensorproduct\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-13974.p
cat coverage.cover
git checkout 84c125972ad535b2dfb245f8d311d347b45e5b8a
git apply /root/pre_state.patch
