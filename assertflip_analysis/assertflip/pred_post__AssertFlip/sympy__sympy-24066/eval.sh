#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 514579c655bf22e2af14f0743376ae1d7befe345 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 514579c655bf22e2af14f0743376ae1d7befe345
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/physics/units/unitsystem.py b/sympy/physics/units/unitsystem.py
--- a/sympy/physics/units/unitsystem.py
+++ b/sympy/physics/units/unitsystem.py
@@ -190,10 +190,9 @@ def _collect_factor_and_dimension(self, expr):
                 dim /= idim**count
             return factor, dim
         elif isinstance(expr, Function):
-            fds = [self._collect_factor_and_dimension(
-                arg) for arg in expr.args]
-            return (expr.func(*(f[0] for f in fds)),
-                    *(d[1] for d in fds))
+            fds = [self._collect_factor_and_dimension(arg) for arg in expr.args]
+            dims = [Dimension(1) if self.get_dimension_system().is_dimensionless(d[1]) else d[1] for d in fds]
+            return (expr.func(*(f[0] for f in fds)), *dims)
         elif isinstance(expr, Dimension):
             return S.One, expr
         else:

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-24066.py
new file mode 100644
index e69de29..06445a6 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-24066.py
@@ -0,0 +1,14 @@
+from sympy import exp
+from sympy.physics import units
+from sympy.physics.units.systems.si import SI
+
+def test_dimensionless_exponent_bug():
+    # Setup the expression
+    expr = units.second / (units.ohm * units.farad)
+    buggy_expr = 100 + exp(expr)
+    
+    # Assert the correct behavior: no exception should be raised
+    try:
+        SI._collect_factor_and_dimension(buggy_expr)
+    except ValueError:
+        assert False, "ValueError raised, but the expression should be dimensionless."

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/physics/units/unitsystem\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-24066.p
cat coverage.cover
git checkout 514579c655bf22e2af14f0743376ae1d7befe345
git apply /root/pre_state.patch
