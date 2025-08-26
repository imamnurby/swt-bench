#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 553b5fb8f84ba05c8397f26dd079deece2b05029 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 553b5fb8f84ba05c8397f26dd079deece2b05029
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-11310.py
new file mode 100644
index e69de29..3db244d 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-11310.py
@@ -0,0 +1,22 @@
+import pytest
+from sklearn.datasets import load_iris
+from sklearn.model_selection import GridSearchCV
+from sklearn.ensemble import RandomForestClassifier
+
+def test_missing_refit_time_attribute():
+    # Load a simple dataset
+    X, y = load_iris(return_X_y=True)
+    
+    # Set up the estimator and parameter grid
+    estimator = RandomForestClassifier()
+    param_grid = {'n_estimators': [2, 3]}
+    
+    # Initialize GridSearchCV
+    grid_search = GridSearchCV(estimator=estimator, param_grid=param_grid, refit=True)
+    
+    # Fit the model
+    grid_search.fit(X, y)
+    
+    # Check if the refit_time_ attribute exists and is a float
+    assert hasattr(grid_search, 'refit_time_'), "refit_time_ attribute is missing"
+    assert isinstance(grid_search.refit_time_, float), "refit_time_ should be a float"

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/model_selection/_search\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-11310.py
cat coverage.cover
git checkout 553b5fb8f84ba05c8397f26dd079deece2b05029
git apply /root/pre_state.patch
