#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 3eacf948e0f95ef957862568d87ce082f378e186 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 3eacf948e0f95ef957862568d87ce082f378e186
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-9288.py
new file mode 100644
index e69de29..a0cc18b 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-9288.py
@@ -0,0 +1,20 @@
+import pytest
+from sklearn.cluster import KMeans
+from sklearn.datasets import make_blobs
+
+def test_kmeans_inertia_with_different_n_jobs():
+    # Generate synthetic dataset
+    X, _ = make_blobs(n_samples=10000, centers=10, n_features=2, random_state=2)
+
+    # Run KMeans with n_jobs=1
+    kmeans_1 = KMeans(n_clusters=10, random_state=2, n_jobs=1)
+    kmeans_1.fit(X)
+    inertia_1 = kmeans_1.inertia_
+
+    # Run KMeans with n_jobs=2
+    kmeans_2 = KMeans(n_clusters=10, random_state=2, n_jobs=2)
+    kmeans_2.fit(X)
+    inertia_2 = kmeans_2.inertia_
+
+    # Assert that the inertia values are the same
+    assert inertia_1 == inertia_2, "Inertia values should be the same with different n_jobs settings"

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/cluster/k_means_\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-9288.py
cat coverage.cover
git checkout 3eacf948e0f95ef957862568d87ce082f378e186
git apply /root/pre_state.patch
