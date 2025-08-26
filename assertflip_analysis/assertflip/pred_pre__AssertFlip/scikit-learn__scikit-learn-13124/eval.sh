#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 9f0b959a8c9195d1b6e203f08b698e052b426ca9 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 9f0b959a8c9195d1b6e203f08b698e052b426ca9
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-13124.py
new file mode 100644
index e69de29..c309741 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-13124.py
@@ -0,0 +1,23 @@
+import numpy as np
+from sklearn.model_selection import StratifiedKFold
+import pytest
+
+def test_stratified_kfold_shuffle_bug():
+    # Setup
+    RANDOM_SEED = 1
+    samples_per_class = 10
+    X = np.linspace(0, samples_per_class * 2 - 1, samples_per_class * 2)
+    y = np.concatenate((np.ones(samples_per_class), np.zeros(samples_per_class)), axis=0)
+
+    # Initialize StratifiedKFold with shuffle=True and a fixed random_state
+    k_fold = StratifiedKFold(n_splits=10, shuffle=True, random_state=RANDOM_SEED)
+    test_indices = [sorted(test_idx) for _, test_idx in k_fold.split(X, y)]
+
+    # Check if the content of batches changes when shuffle=True
+    # This assertion will fail if the bug is present, as the content should change
+    # due to shuffling, but it doesn't.
+    for i in range(len(test_indices) - 1):
+        assert test_indices[i] == test_indices[i + 1], \
+            "The content of batches should change when shuffle=True, but it doesn't."
+
+# Note: The test is expected to fail if the bug is present, as the content of batches will remain unchanged.

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/model_selection/_split\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-13124.py
cat coverage.cover
git checkout 9f0b959a8c9195d1b6e203f08b698e052b426ca9
git apply /root/pre_state.patch
