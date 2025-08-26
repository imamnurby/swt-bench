#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 3aefc834dce72e850bff48689bea3c7dff5f3fad >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 3aefc834dce72e850bff48689bea3c7dff5f3fad
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-13496.py
new file mode 100644
index e69de29..bbd15f4 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-13496.py
@@ -0,0 +1,41 @@
+import pytest
+from sklearn.ensemble import IsolationForest
+import numpy as np
+
+def test_isolation_forest_warm_start_behavior():
+    # Create a synthetic dataset
+    X = np.random.rand(100, 2)
+
+    # Initial number of estimators
+    n_estimators_initial = 10
+    n_estimators_incremented = 20
+
+    # Initialize IsolationForest without warm_start in __init__
+    model = IsolationForest(n_estimators=n_estimators_initial)
+
+    # Manually set warm_start to True
+    model.warm_start = True
+
+    # Fit the model with the initial number of estimators
+    model.fit(X)
+
+    # Store the number of estimators after the first fit
+    n_estimators_after_first_fit = len(model.estimators_)
+
+    # Increment n_estimators
+    model.n_estimators = n_estimators_incremented
+
+    # Fit the model again with the same data
+    model.fit(X)
+
+    # Store the number of estimators after the second fit
+    n_estimators_after_second_fit = len(model.estimators_)
+
+    # Assert that the number of estimators after the first fit is equal to n_estimators_initial
+    assert n_estimators_after_first_fit == n_estimators_initial, \
+        "BUG: The number of estimators after the first fit should be equal to n_estimators_initial"
+
+    # Assert that the number of estimators after the second fit is equal to the sum of initial and incremented
+    assert n_estimators_after_second_fit == n_estimators_initial + n_estimators_incremented, \
+        "The number of estimators after the second fit should be equal to the sum of n_estimators_initial and n_estimators_incremented"
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/ensemble/iforest\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-13496.py
cat coverage.cover
git checkout 3aefc834dce72e850bff48689bea3c7dff5f3fad
git apply /root/pre_state.patch
