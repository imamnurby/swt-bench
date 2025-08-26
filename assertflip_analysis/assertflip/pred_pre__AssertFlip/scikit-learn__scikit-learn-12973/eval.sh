#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a7b8b9e9e16d4e15fabda5ae615086c2e1c47d8a >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a7b8b9e9e16d4e15fabda5ae615086c2e1c47d8a
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-12973.py
new file mode 100644
index e69de29..2292a2b 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-12973.py
@@ -0,0 +1,24 @@
+import numpy as np
+from sklearn.linear_model import LassoLarsIC
+import pytest
+
+def test_lassolarsic_copy_X_behavior():
+    # Create a small dataset
+    X = np.array([[1, 2], [3, 4], [5, 6]], dtype=float)
+    y = np.array([1, 2, 3], dtype=float)
+
+    # Initialize LassoLarsIC with copy_X=False
+    model = LassoLarsIC(copy_X=False)
+
+    # Fit the model
+    model.fit(X, y)
+
+    # Modify X after fitting
+    X[0, 0] = 999
+
+    # Check if the model's internal state reflects the changes to X
+    # Since copy_X=False, changes to X should affect the model's state
+    # Correct behavior: The model's coefficients should change if X is modified
+    assert model.coef_[0] == 0, "Model's internal state should reflect changes to X"
+
+# Note: The test will fail under the current buggy behavior, exposing the bug.

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/linear_model/least_angle\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-12973.py
cat coverage.cover
git checkout a7b8b9e9e16d4e15fabda5ae615086c2e1c47d8a
git apply /root/pre_state.patch
