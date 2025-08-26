#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD de446c6d85f633271dfec1452f6f28ea783e293f >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff de446c6d85f633271dfec1452f6f28ea783e293f
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/physics/secondquant.py b/sympy/physics/secondquant.py
--- a/sympy/physics/secondquant.py
+++ b/sympy/physics/secondquant.py
@@ -218,7 +218,7 @@ def _sortkey(cls, index):
             return (12, label, h)
 
     def _latex(self, printer):
-        return "%s^{%s}_{%s}" % (
+        return "{%s^{%s}_{%s}}" % (
             self.symbol,
             "".join([ i.name for i in self.args[1]]),
             "".join([ i.name for i in self.args[2]])
@@ -478,7 +478,7 @@ def __repr__(self):
         return "CreateBoson(%s)" % self.state
 
     def _latex(self, printer):
-        return "b^\\dagger_{%s}" % self.state.name
+        return "{b^\\dagger_{%s}}" % self.state.name
 
 B = AnnihilateBoson
 Bd = CreateBoson
@@ -939,7 +939,7 @@ def __repr__(self):
         return "CreateFermion(%s)" % self.state
 
     def _latex(self, printer):
-        return "a^\\dagger_{%s}" % self.state.name
+        return "{a^\\dagger_{%s}}" % self.state.name
 
 Fd = CreateFermion
 F = AnnihilateFermion

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-21930.py
new file mode 100644
index e69de29..1fb618f 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-21930.py
@@ -0,0 +1,20 @@
+from sympy import Symbol
+from sympy.physics.secondquant import B, Bd, Commutator
+from sympy import init_printing
+from sympy.printing.latex import latex
+
+def test_latex_rendering_issue():
+    # Initialize Latex printing
+    init_printing()
+
+    # Create a symbol
+    a = Symbol('0')
+
+    # Construct the commutator expression
+    expr = Commutator(Bd(a)**2, B(a))
+
+    # Capture the Latex output using the latex function
+    latex_output = latex(expr)
+
+    # Assert that the correct format is present
+    assert "{b^\\dagger_{0}}^{2}" in latex_output

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/physics/secondquant\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-21930.p
cat coverage.cover
git checkout de446c6d85f633271dfec1452f6f28ea783e293f
git apply /root/pre_state.patch
