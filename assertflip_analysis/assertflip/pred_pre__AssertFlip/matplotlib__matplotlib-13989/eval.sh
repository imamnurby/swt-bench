#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a3e2897bfaf9eaac1d6649da535c4e721c89fa69 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a3e2897bfaf9eaac1d6649da535c4e721c89fa69
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/lib/matplotlib/tests/test_coverup_matplotlib__matplotlib-13989.py
new file mode 100644
index e69de29..f074e05 100644
--- /dev/null
+++ b/lib/matplotlib/tests/test_coverup_matplotlib__matplotlib-13989.py
@@ -0,0 +1,20 @@
+import pytest
+import matplotlib.pyplot as plt
+import numpy as np
+
+def test_hist_density_range_bug():
+    # Set a random seed for reproducibility
+    np.random.seed(0)
+    
+    # Generate random data
+    data = np.random.rand(10)
+    
+    # Create a histogram with density=True and range=(0, 1)
+    _, bins, _ = plt.hist(data, bins='auto', range=(0, 1), density=True)
+    
+    # Assert that the first bin edge is 0 and the last bin edge is 1
+    assert bins[0] == 0, "The first bin edge should be 0."
+    assert bins[-1] == 1, "The last bin edge should be 1."
+
+    # Cleanup: Close the plot to avoid state pollution
+    plt.close()

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(lib/matplotlib/axes/_axes\.py)' -m pytest --no-header -rA  -p no:cacheprovider lib/matplotlib/tests/test_coverup_matplotlib__matplotlib-13989.py
cat coverage.cover
git checkout a3e2897bfaf9eaac1d6649da535c4e721c89fa69
git apply /root/pre_state.patch
