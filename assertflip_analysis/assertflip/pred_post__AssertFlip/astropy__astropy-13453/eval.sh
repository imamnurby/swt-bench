#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 19cc80471739bcb67b7e8099246b391c355023ee >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 19cc80471739bcb67b7e8099246b391c355023ee
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/astropy/io/ascii/html.py b/astropy/io/ascii/html.py
--- a/astropy/io/ascii/html.py
+++ b/astropy/io/ascii/html.py
@@ -349,11 +349,13 @@ def write(self, table):
         cols = list(table.columns.values())
 
         self.data.header.cols = cols
+        self.data.cols = cols
 
         if isinstance(self.data.fill_values, tuple):
             self.data.fill_values = [self.data.fill_values]
 
         self.data._set_fill_values(cols)
+        self.data._set_col_formats()
 
         lines = []
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-13453.py
new file mode 100644
index e69de29..3e32b75 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-13453.py
@@ -0,0 +1,17 @@
+import pytest
+from astropy.table import Table
+from io import StringIO
+
+def test_html_format_ignored():
+    # Create a table with columns that require specific formatting
+    t = Table([(1.23875234858e-24, 3.2348748432e-15), (2, 4)], names=('a', 'b'))
+    tc = t.copy()  # Copy table to ensure original remains unchanged
+
+    # Write the table to a StringIO object in HTML format with the formats argument
+    with StringIO() as sp:
+        tc.write(sp, format="html", formats={"a": lambda x: f"{x:.2e}"})
+        html_output = sp.getvalue()
+
+    # Assert that the formatted column values match the expected formatted output
+    assert "1.24e-24" in html_output
+    assert "3.23e-15" in html_output

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/io/ascii/html\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-13453.py
cat coverage.cover
git checkout 19cc80471739bcb67b7e8099246b391c355023ee
git apply /root/pre_state.patch
