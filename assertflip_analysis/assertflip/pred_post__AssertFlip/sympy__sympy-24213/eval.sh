#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD e8c22f6eac7314be8d92590bfff92ced79ee03e2 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff e8c22f6eac7314be8d92590bfff92ced79ee03e2
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/physics/units/unitsystem.py b/sympy/physics/units/unitsystem.py
--- a/sympy/physics/units/unitsystem.py
+++ b/sympy/physics/units/unitsystem.py
@@ -175,7 +175,7 @@ def _collect_factor_and_dimension(self, expr):
             for addend in expr.args[1:]:
                 addend_factor, addend_dim = \
                     self._collect_factor_and_dimension(addend)
-                if dim != addend_dim:
+                if not self.get_dimension_system().equivalent_dims(dim, addend_dim):
                     raise ValueError(
                         'Dimension of "{}" is {}, '
                         'but it should be {}'.format(

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-24213.py
new file mode 100644
index e69de29..8d6513d 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-24213.py
@@ -0,0 +1,23 @@
+from sympy.physics import units
+from sympy.physics.units.systems.si import SI
+
+def test_collect_factor_and_dimension_equivalent_dimensions():
+    # Setup quantities with equivalent dimensions
+    v1 = units.Quantity('v1')
+    SI.set_quantity_dimension(v1, units.velocity)
+    SI.set_quantity_scale_factor(v1, 2 * units.meter / units.second)
+
+    a1 = units.Quantity('a1')
+    SI.set_quantity_dimension(a1, units.acceleration)
+    SI.set_quantity_scale_factor(a1, -9.8 * units.meter / units.second**2)
+
+    t1 = units.Quantity('t1')
+    SI.set_quantity_dimension(t1, units.time)
+    SI.set_quantity_scale_factor(t1, 5 * units.second)
+
+    # Construct expression with equivalent dimensions
+    expr1 = a1 * t1 + v1
+
+    # Call the method and assert the correct behavior
+    # The test should pass when the bug is fixed and no exception is raised
+    SI._collect_factor_and_dimension(expr1)

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/physics/units/unitsystem\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-24213.p
cat coverage.cover
git checkout e8c22f6eac7314be8d92590bfff92ced79ee03e2
git apply /root/pre_state.patch
