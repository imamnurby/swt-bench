#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d65c9ca20ddf81ef91199e6d819f9d3506ef477c >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d65c9ca20ddf81ef91199e6d819f9d3506ef477c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/lib/matplotlib/tests/test_coverup_matplotlib__matplotlib-14623.py
new file mode 100644
index e69de29..e4a59a3 100644
--- /dev/null
+++ b/lib/matplotlib/tests/test_coverup_matplotlib__matplotlib-14623.py
@@ -0,0 +1,23 @@
+import numpy as np
+import matplotlib.pyplot as plt
+import pytest
+
+def test_invert_axis_log_scale():
+    # Create a dataset with values suitable for both linear and log scales
+    y = np.linspace(1000e2, 1, 100)
+    x = np.exp(-np.linspace(0, 1, y.size))
+
+    # Iterate over both linear and log scales
+    for yscale in ('linear', 'log'):
+        fig, ax = plt.subplots()
+        ax.plot(x, y)
+        ax.set_yscale(yscale)
+        ax.set_ylim(y.max(), y.min())  # Attempt to invert the y-axis
+
+        # Capture the y-axis limits after setting them
+        bottom, top = ax.get_ylim()
+
+        # Assert that the y-axis limits are inverted for both linear and log scales
+        assert bottom > top, f"{yscale.capitalize()} scale: y-axis should be inverted"
+
+        plt.close(fig)  # Cleanup to avoid state pollution

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(lib/matplotlib/ticker\.py|lib/mpl_toolkits/mplot3d/axes3d\.py|lib/matplotlib/axes/_base\.py)' -m pytest --no-header -rA  -p no:cacheprovider lib/matplotlib/tests/test_coverup_matplotlib__matplotlib-14623.py
cat coverage.cover
git checkout d65c9ca20ddf81ef91199e6d819f9d3506ef477c
git apply /root/pre_state.patch
