#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 4aded39b5663d943f6a4809abacfa9cae3d7fb6a >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 4aded39b5663d943f6a4809abacfa9cae3d7fb6a
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14629.py
new file mode 100644
index e69de29..269cd4f 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14629.py
@@ -0,0 +1,18 @@
+import pytest
+from sklearn.datasets import make_multilabel_classification
+from sklearn.multioutput import MultiOutputClassifier
+from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
+from sklearn.model_selection import cross_val_predict
+
+def test_cross_val_predict_with_multioutputclassifier_predict_proba():
+    # Generate a multilabel classification dataset
+    X, Y = make_multilabel_classification(n_samples=100, n_features=20, n_classes=3, n_labels=2, random_state=42)
+
+    # Initialize a MultiOutputClassifier with LinearDiscriminantAnalysis
+    mo_lda = MultiOutputClassifier(LinearDiscriminantAnalysis())
+
+    # Expect the function to run without errors and return an array of prediction probabilities
+    pred_proba = cross_val_predict(mo_lda, X, Y, cv=5, method='predict_proba')
+    
+    # Check if the output is of the expected shape
+    assert pred_proba.shape == (100, 3, 2)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/multioutput\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-14629.py
cat coverage.cover
git checkout 4aded39b5663d943f6a4809abacfa9cae3d7fb6a
git apply /root/pre_state.patch
