#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 3d997697fdd166eff428ea9fd35734b6a8ba113e >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 3d997697fdd166eff428ea9fd35734b6a8ba113e
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sklearn/utils/_show_versions.py b/sklearn/utils/_show_versions.py
--- a/sklearn/utils/_show_versions.py
+++ b/sklearn/utils/_show_versions.py
@@ -48,6 +48,7 @@ def _get_deps_info():
         "Cython",
         "pandas",
         "matplotlib",
+        "joblib",
     ]
 
     def get_version(module):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14141.py
new file mode 100644
index e69de29..35aa145 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14141.py
@@ -0,0 +1,12 @@
+import pytest
+from unittest.mock import patch
+from sklearn.utils._show_versions import _get_deps_info
+
+def test_joblib_presence_in_deps_info():
+    # Mock the sklearn version to be greater than 0.20
+    with patch('sklearn.__version__', '0.22.dev0'):
+        # Call the function to get dependencies info
+        deps_info = _get_deps_info()
+        
+        # Assert that 'joblib' is present in the dependencies info
+        assert 'joblib' in deps_info

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/utils/_show_versions\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-14141.py
cat coverage.cover
git checkout 3d997697fdd166eff428ea9fd35734b6a8ba113e
git apply /root/pre_state.patch
