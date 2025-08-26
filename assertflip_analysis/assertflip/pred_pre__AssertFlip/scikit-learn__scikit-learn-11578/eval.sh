#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD dd69361a0d9c6ccde0d2353b00b86e0e7541a3e3 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff dd69361a0d9c6ccde0d2353b00b86e0e7541a3e3
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-11578.py
new file mode 100644
index e69de29..cc4f378 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-11578.py
@@ -0,0 +1,50 @@
+import numpy as np
+import pytest
+from sklearn.linear_model import LogisticRegressionCV, LogisticRegression
+from sklearn.linear_model.logistic import _log_reg_scoring_path
+from sklearn.preprocessing import LabelBinarizer
+from sklearn.utils import extmath
+
+def test_log_reg_scoring_path_multinomial_bug():
+    # Setup synthetic data
+    np.random.seed(1234)
+    samples = 200
+    features = 5
+    folds = 10
+
+    X = np.random.random(size=(samples, features))
+    y = np.random.choice(['a', 'b', 'c'], size=samples)
+
+    test_indices = np.random.choice(range(samples), size=int(samples / folds), replace=False)
+    train_indices = [idx for idx in range(samples) if idx not in test_indices]
+
+    # Binarize the labels for y[test]
+    lb = LabelBinarizer()
+    lb.fit(y[test_indices])
+    y_bin = lb.transform(y[test_indices])
+
+    # Use LogisticRegressionCV to get expected multinomial scores
+    log_reg_cv = LogisticRegressionCV(multi_class='multinomial', solver='lbfgs', cv=folds)
+    log_reg_cv.fit(X[train_indices], y[train_indices])
+    expected_probs = log_reg_cv.predict_proba(X[test_indices])
+
+    # Call _log_reg_scoring_path with multi_class='multinomial'
+    coefs, _, scores, _ = _log_reg_scoring_path(X, y, train_indices, test_indices, fit_intercept=True, scoring='neg_log_loss', multi_class='multinomial')
+
+    # Initialize a LogisticRegression instance with the same coefficients
+    log_reg = LogisticRegression(fit_intercept=True, multi_class='multinomial')
+    log_reg.coef_ = coefs[0][:, :-1]
+    log_reg.intercept_ = coefs[0][:, -1]
+
+    # Get probabilities using predict_proba
+    actual_probs = log_reg.predict_proba(X[test_indices])
+
+    # Assert that the probabilities match the expected multinomial probabilities
+    assert np.allclose(actual_probs, expected_probs), "Probabilities should match when the bug is fixed"
+
+    # Assert that the scores match the expected multinomial scores
+    expected_score = -np.mean(np.sum(y_bin * np.log(expected_probs), axis=1))
+    actual_score = scores[0]
+    assert np.isclose(actual_score, expected_score), "Scores should match when the bug is fixed"
+
+# Note: The test will fail if the bug is present.

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/linear_model/logistic\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-11578.py
cat coverage.cover
git checkout dd69361a0d9c6ccde0d2353b00b86e0e7541a3e3
git apply /root/pre_state.patch
