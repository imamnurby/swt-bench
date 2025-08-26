#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 54cab15bdacfaa05a88fbc5502a5b322d99f148e >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 54cab15bdacfaa05a88fbc5502a5b322d99f148e
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[dev]
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_mwaskom__seaborn-3069.py
new file mode 100644
index e69de29..1596942 100644
--- /dev/null
+++ b/tests/test_coverup_mwaskom__seaborn-3069.py
@@ -0,0 +1,27 @@
+import pytest
+import matplotlib.pyplot as plt
+import seaborn as sns
+
+def test_nominal_scale_axis_limits_and_grid():
+    # Create a sample dataset with nominal categories
+    data = {'Category': ['A', 'B', 'C'], 'Value': [1, 2, 3]}
+    
+    # Initialize a seaborn plot using this dataset with a Nominal scale
+    fig, ax = plt.subplots()
+    sns.barplot(x='Category', y='Value', data=data, ax=ax)
+    
+    # Render the plot
+    plt.draw()
+    
+    # Capture the axis properties
+    xlim = ax.get_xlim()
+    grid_visible = ax.xaxis._gridOnMajor if hasattr(ax.xaxis, '_gridOnMajor') else ax.xaxis.get_gridlines()[0].get_visible()
+    
+    # Assert that the axis limits are correctly set to the normal margin logic
+    assert xlim != (-0.5, 2.5), "Axis limits are incorrectly set to +/- 0.5 from the first and last tick"
+    
+    # Assert that grid lines are not visible
+    assert grid_visible, "Grid lines are not visible when they should be"
+    
+    # Cleanup: Close the plot to free resources
+    plt.close(fig)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(seaborn/_core/plot\.py)' -m pytest --no-header -rA tests/test_coverup_mwaskom__seaborn-3069.py
cat coverage.cover
git checkout 54cab15bdacfaa05a88fbc5502a5b322d99f148e
git apply /root/pre_state.patch
