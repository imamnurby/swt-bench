#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a061ada48efccf0845acae17009553e01764452b >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a061ada48efccf0845acae17009553e01764452b
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sklearn/preprocessing/_discretization.py b/sklearn/preprocessing/_discretization.py
--- a/sklearn/preprocessing/_discretization.py
+++ b/sklearn/preprocessing/_discretization.py
@@ -172,6 +172,8 @@ def fit(self, X, y=None):
                 # 1D k-means procedure
                 km = KMeans(n_clusters=n_bins[jj], init=init, n_init=1)
                 centers = km.fit(column[:, None]).cluster_centers_[:, 0]
+                # Must sort, centers may be unsorted even with sorted init
+                centers.sort()
                 bin_edges[jj] = (centers[1:] + centers[:-1]) * 0.5
                 bin_edges[jj] = np.r_[col_min, bin_edges[jj], col_max]
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-13135.py
new file mode 100644
index e69de29..6325f77 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-13135.py
@@ -0,0 +1,15 @@
+import numpy as np
+import pytest
+from sklearn.preprocessing import KBinsDiscretizer
+
+def test_kmeans_strategy_unsorted_bin_edges():
+    # Test setup
+    X = np.array([0, 0.5, 2, 3, 9, 10]).reshape(-1, 1)
+    n_bins = 5
+    est = KBinsDiscretizer(n_bins=n_bins, strategy='kmeans', encode='ordinal')
+    
+    # Test that no ValueError is raised when bin_edges are sorted correctly
+    try:
+        est.fit_transform(X)
+    except ValueError as e:
+        assert False, f"Unexpected ValueError raised: {e}"

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/preprocessing/_discretization\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-13135.py
cat coverage.cover
git checkout a061ada48efccf0845acae17009553e01764452b
git apply /root/pre_state.patch
