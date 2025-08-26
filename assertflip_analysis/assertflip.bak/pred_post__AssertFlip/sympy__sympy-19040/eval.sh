#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD b9179e80d2daa1bb6cba1ffe35ca9e6612e115c9 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff b9179e80d2daa1bb6cba1ffe35ca9e6612e115c9
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sympy/polys/factortools.py b/sympy/polys/factortools.py
--- a/sympy/polys/factortools.py
+++ b/sympy/polys/factortools.py
@@ -1147,7 +1147,7 @@ def dmp_ext_factor(f, u, K):
         return lc, []
 
     f, F = dmp_sqf_part(f, u, K), f
-    s, g, r = dmp_sqf_norm(f, u, K)
+    s, g, r = dmp_sqf_norm(F, u, K)
 
     factors = dmp_factor_list_include(r, u, K.dom)
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sympy/polys/tests/test_coverup_sympy__sympy-19040.py
new file mode 100644
index e69de29..69d35fd 100644
--- /dev/null
+++ b/sympy/polys/tests/test_coverup_sympy__sympy-19040.py
@@ -0,0 +1,12 @@
+from sympy import factor, expand, I
+from sympy.abc import x, y
+
+def test_factor_with_extension_bug():
+    # Define the polynomial z
+    z = expand((x - 1) * (y - 1))
+    
+    # Factor the polynomial with extension=[I]
+    result = factor(z, extension=[I])
+    
+    # Assert that the result is equal to the expected correct factorization
+    assert result == (x - 1) * (y - 1)

EOF_114329324912
PYTHONWARNINGS='ignore::UserWarning,ignore::SyntaxWarning' python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sympy/polys/factortools\.py)' bin/test -C --verbose sympy/polys/tests/test_coverup_sympy__sympy-19040.p
cat coverage.cover
git checkout b9179e80d2daa1bb6cba1ffe35ca9e6612e115c9
git apply /root/pre_state.patch
