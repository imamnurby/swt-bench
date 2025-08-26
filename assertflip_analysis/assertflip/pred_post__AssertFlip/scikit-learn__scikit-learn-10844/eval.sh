#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 97523985b39ecde369d83352d7c3baf403b60a22 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 97523985b39ecde369d83352d7c3baf403b60a22
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sklearn/metrics/cluster/supervised.py b/sklearn/metrics/cluster/supervised.py
--- a/sklearn/metrics/cluster/supervised.py
+++ b/sklearn/metrics/cluster/supervised.py
@@ -852,11 +852,12 @@ def fowlkes_mallows_score(labels_true, labels_pred, sparse=False):
     labels_true, labels_pred = check_clusterings(labels_true, labels_pred)
     n_samples, = labels_true.shape
 
-    c = contingency_matrix(labels_true, labels_pred, sparse=True)
+    c = contingency_matrix(labels_true, labels_pred,
+                           sparse=True).astype(np.int64)
     tk = np.dot(c.data, c.data) - n_samples
     pk = np.sum(np.asarray(c.sum(axis=0)).ravel() ** 2) - n_samples
     qk = np.sum(np.asarray(c.sum(axis=1)).ravel() ** 2) - n_samples
-    return tk / np.sqrt(pk * qk) if tk != 0. else 0.
+    return np.sqrt(tk / pk) * np.sqrt(tk / qk) if tk != 0. else 0.
 
 
 def entropy(labels):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-10844.py
new file mode 100644
index e69de29..0597851 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-10844.py
@@ -0,0 +1,19 @@
+import pytest
+import numpy as np
+from sklearn.metrics.cluster import fowlkes_mallows_score
+
+def test_fowlkes_mallows_score_overflow():
+    # Create large label arrays to trigger overflow
+    # These arrays are designed to create large pk and qk values
+    labels_true = np.array([0] * 100000 + [1] * 100000)
+    labels_pred = np.array([0] * 50000 + [1] * 50000 + [2] * 50000 + [3] * 50000)
+
+    # Call the fowlkes_mallows_score function
+    score = fowlkes_mallows_score(labels_true, labels_pred)
+
+    # Assert that the score is not nan, indicating the bug is fixed
+    assert not np.isnan(score), "BUG: Expected a valid score, but got nan due to overflow"
+
+# Note: This test is expected to fail by confirming the presence of the bug.
+# Once the bug is fixed, the test should pass, indicating the function now returns a valid float without warnings.
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/metrics/cluster/supervised\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-10844.py
cat coverage.cover
git checkout 97523985b39ecde369d83352d7c3baf403b60a22
git apply /root/pre_state.patch
