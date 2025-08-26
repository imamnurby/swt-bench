#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 1923822ddf8265199dbd9ef9ce09641d3fd042b9 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 1923822ddf8265199dbd9ef9ce09641d3fd042b9
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/solvers/diophantine.py b/sympy/solvers/diophantine.py
--- a/sympy/solvers/diophantine.py
+++ b/sympy/solvers/diophantine.py
@@ -182,7 +182,7 @@ def diophantine(eq, param=symbols("t", integer=True), syms=None,
             if syms != var:
                 dict_sym_index = dict(zip(syms, range(len(syms))))
                 return {tuple([t[dict_sym_index[i]] for i in var])
-                            for t in diophantine(eq, param)}
+                            for t in diophantine(eq, param, permute=permute)}
         n, d = eq.as_numer_denom()
         if n.is_number:
             return set()

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-18189.py
new file mode 100644
index e69de29..c85d627 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-18189.py
@@ -0,0 +1,11 @@
+from sympy.solvers.diophantine import diophantine
+from sympy.abc import m, n
+from sympy import S
+
+def test_diophantine_permute_syms_order_bug():
+    eq = n**4 + m**4 - 2**4 - 3**4
+    result_mn = diophantine(eq, syms=(m, n), permute=True)
+    result_nm = diophantine(eq, syms=(n, m), permute=True)
+    
+    # The results should be the same regardless of the order of syms.
+    assert result_mn == result_nm

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/solvers/diophantine\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-18189.p
cat coverage.cover
git checkout 1923822ddf8265199dbd9ef9ce09641d3fd042b9
git apply /root/pre_state.patch
