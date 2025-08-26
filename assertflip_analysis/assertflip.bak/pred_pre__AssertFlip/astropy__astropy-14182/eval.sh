#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a5917978be39d13cd90b517e1de4e7a539ffaa48 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a5917978be39d13cd90b517e1de4e7a539ffaa48
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-14182.py
new file mode 100644
index e69de29..4a149cc 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-14182.py
@@ -0,0 +1,24 @@
+import pytest
+from astropy.table import QTable
+import astropy.units as u
+import io
+
+def test_rst_writer_with_header_rows_does_not_raise_type_error():
+    # Setup: Create a QTable with sample data
+    tbl = QTable({'wave': [350, 950] * u.nm, 'response': [0.7, 1.2] * u.count})
+    
+    # Use an in-memory buffer instead of a file to avoid file system issues
+    output_buffer = io.StringIO()
+    
+    # Test: Attempt to write the table using the ascii.rst format with header_rows specified
+    try:
+        tbl.write(output_buffer, format="ascii.rst", header_rows=["name", "unit"])
+    except TypeError as excinfo:
+        pytest.fail(f"Unexpected TypeError raised: {excinfo}")
+    
+    # Assert: Check the output to ensure it includes the header rows correctly
+    output = output_buffer.getvalue()
+    assert "wave" in output
+    assert "response" in output
+    assert "nm" in output
+    assert "ct" in output

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/io/ascii/rst\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-14182.py
cat coverage.cover
git checkout a5917978be39d13cd90b517e1de4e7a539ffaa48
git apply /root/pre_state.patch
