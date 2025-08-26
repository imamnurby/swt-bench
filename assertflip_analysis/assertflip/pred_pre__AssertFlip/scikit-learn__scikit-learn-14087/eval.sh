#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a5743ed36fbd3fbc8e351bdab16561fbfca7dfa1 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a5743ed36fbd3fbc8e351bdab16561fbfca7dfa1
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14087.py
new file mode 100644
index e69de29..b73dd86 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14087.py
@@ -0,0 +1,22 @@
+import pytest
+import numpy as np
+from sklearn.linear_model import LogisticRegressionCV
+
+def test_logistic_regression_cv_refit_false_index_error():
+    # Set random seed for reproducibility
+    np.random.seed(29)
+    
+    # Generate random data
+    X = np.random.normal(size=(1000, 3))
+    beta = np.random.normal(size=3)
+    intercept = np.random.normal(size=None)
+    y = np.sign(intercept + X @ beta)
+    
+    # Initialize LogisticRegressionCV with refit=False
+    model = LogisticRegressionCV(cv=5, solver='saga', tol=1e-2, refit=False)
+    
+    # Expect no error to be raised when the bug is fixed
+    try:
+        model.fit(X, y)
+    except IndexError:
+        pytest.fail("IndexError was raised with refit=False, indicating a bug.")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/linear_model/logistic\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-14087.py
cat coverage.cover
git checkout a5743ed36fbd3fbc8e351bdab16561fbfca7dfa1
git apply /root/pre_state.patch
