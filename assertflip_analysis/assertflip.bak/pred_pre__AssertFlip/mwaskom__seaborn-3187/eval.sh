#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 22cdfb0c93f8ec78492d87edb810f10cb7f57a31 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 22cdfb0c93f8ec78492d87edb810f10cb7f57a31
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[dev]
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_mwaskom__seaborn-3187.py
new file mode 100644
index e69de29..fa269d5 100644
--- /dev/null
+++ b/tests/test_coverup_mwaskom__seaborn-3187.py
@@ -0,0 +1,30 @@
+import pytest
+import seaborn as sns
+import matplotlib.pyplot as plt
+import matplotlib as mpl
+
+def test_legend_values_with_offset():
+    # Set matplotlib rcParams to use offset
+    mpl.rcParams['axes.formatter.useoffset'] = True
+
+    # Load dataset and create a column with large values
+    penguins = sns.load_dataset("penguins")
+    penguins["body_mass_mg"] = penguins["body_mass_g"] * 1000
+
+    # Create a plot using seaborn with the large values column affecting the legend
+    ax = sns.scatterplot(
+        data=penguins, x="bill_length_mm", y="bill_depth_mm",
+        hue="species", size="body_mass_mg", legend="full"
+    )
+
+    # Retrieve the legend from the plot
+    legend = ax.get_legend()
+
+    # Check the legend values to confirm they include the offset
+    if legend is not None:
+        labels = [text.get_text() for text in legend.get_texts()]
+        # The legend values should include the offset
+        assert all('e' in label for label in labels), "Legend values do not include offset notation"
+
+    # Cleanup: Close the plot to avoid memory issues
+    plt.close('all')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(seaborn/utils\.py|seaborn/_core/scales\.py)' -m pytest --no-header -rA tests/test_coverup_mwaskom__seaborn-3187.py
cat coverage.cover
git checkout 22cdfb0c93f8ec78492d87edb810f10cb7f57a31
git apply /root/pre_state.patch
