#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 205da797006360fc629110937e39a19c9561313e >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 205da797006360fc629110937e39a19c9561313e
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-14531.py
new file mode 100644
index e69de29..9957fd2 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-14531.py
@@ -0,0 +1,13 @@
+from sympy import Symbol, S, Eq, Limit
+from sympy.printing.str import sstr
+
+def test_sstr_eq_sympy_integers_bug():
+    x = Symbol('x')
+    y = S(1)/2
+    result = sstr(Eq(x, y), sympy_integers=True)
+    assert result == "Eq(x, S(1)/2)"
+
+def test_sstr_limit_sympy_integers_bug():
+    x = Symbol('x')
+    result = sstr(Limit(x, x, S(1)/2), sympy_integers=True)
+    assert result == "Limit(x, x, S(1)/2)"

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/printing/str\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-14531.p
cat coverage.cover
git checkout 205da797006360fc629110937e39a19c9561313e
git apply /root/pre_state.patch
