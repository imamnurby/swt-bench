#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d49a6f13af2f22228d430ac64ac2b518937800d0 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d49a6f13af2f22228d430ac64ac2b518937800d0
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14496.py
new file mode 100644
index e69de29..52ebf2b 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14496.py
@@ -0,0 +1,17 @@
+import pytest
+import numpy as np
+from sklearn.cluster import OPTICS
+
+def test_optics_min_samples_float_bug():
+    # Create a mock dataset
+    data = np.random.rand(10, 2)  # 10 samples, 2 features
+
+    # Instantiate OPTICS with min_samples as a float less than 1
+    clust = OPTICS(min_samples=0.1)
+
+    # Call fit to trigger the internal computation
+    clust.fit(data)
+
+    # Check if min_samples is correctly converted to an integer after internal computation
+    assert isinstance(clust.min_samples, int), "min_samples should be an integer after computation"
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/cluster/optics_\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-14496.py
cat coverage.cover
git checkout d49a6f13af2f22228d430ac64ac2b518937800d0
git apply /root/pre_state.patch
