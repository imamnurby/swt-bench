#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD b34751b7ed02b2cfcc36037fb729d4360480a299 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff b34751b7ed02b2cfcc36037fb729d4360480a299
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-13779.py
new file mode 100644
index e69de29..0e669ab 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-13779.py
@@ -0,0 +1,27 @@
+import pytest
+import numpy as np
+from sklearn.linear_model import LogisticRegression
+from sklearn.ensemble import RandomForestClassifier, VotingClassifier
+from sklearn.datasets import load_iris
+
+def test_voting_classifier_with_none_estimator():
+    # Load sample dataset
+    X, y = load_iris(return_X_y=True)
+    
+    # Initialize VotingClassifier with two estimators
+    voter = VotingClassifier(
+        estimators=[('lr', LogisticRegression()), ('rf', RandomForestClassifier())]
+    )
+    
+    # Fit the classifier with sample weights
+    voter.fit(X, y, sample_weight=np.ones(y.shape))
+    
+    # Set one estimator to None
+    voter.set_params(lr=None)
+    
+    # Attempt to fit the classifier again with sample weights
+    # Check that no exception is raised, indicating the bug is fixed
+    try:
+        voter.fit(X, y, sample_weight=np.ones(y.shape))
+    except AttributeError:
+        pytest.fail("AttributeError raised when fitting with None estimator, bug not fixed.")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/ensemble/voting\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-13779.py
cat coverage.cover
git checkout b34751b7ed02b2cfcc36037fb729d4360480a299
git apply /root/pre_state.patch
