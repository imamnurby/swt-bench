#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d16bfe05a744909de4b27f5875fe0d4ed41ce607 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d16bfe05a744909de4b27f5875fe0d4ed41ce607
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/astropy/modeling/separable.py b/astropy/modeling/separable.py
--- a/astropy/modeling/separable.py
+++ b/astropy/modeling/separable.py
@@ -242,7 +242,7 @@ def _cstack(left, right):
         cright = _coord_matrix(right, 'right', noutp)
     else:
         cright = np.zeros((noutp, right.shape[1]))
-        cright[-right.shape[0]:, -right.shape[1]:] = 1
+        cright[-right.shape[0]:, -right.shape[1]:] = right
 
     return np.hstack([cleft, cright])
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-12907.py
new file mode 100644
index e69de29..2264cff 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-12907.py
@@ -0,0 +1,18 @@
+import pytest
+from astropy.modeling import models as m
+from astropy.modeling.separable import separability_matrix
+
+def test_separability_matrix_bug():
+    # Create a simple CompoundModel using Linear1D models
+    cm = m.Linear1D(10) & m.Linear1D(5)
+    # Create a more complex CompoundModel using Pix2Sky_TAN and Linear1D models
+    complex_cm = m.Pix2Sky_TAN() & m.Linear1D(10) & m.Linear1D(5)
+    # Nest the CompoundModel within another model to replicate the issue
+    nested_cm = m.Pix2Sky_TAN() & cm
+
+    # Get the separability matrix for the nested model
+    separability = separability_matrix(nested_cm)
+
+    # Assert that the separability matrix for the nested model is diagonal
+    assert separability[2][2] == True and separability[2][3] == False
+    assert separability[3][2] == False and separability[3][3] == True

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/modeling/separable\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-12907.py
cat coverage.cover
git checkout d16bfe05a744909de4b27f5875fe0d4ed41ce607
git apply /root/pre_state.patch
