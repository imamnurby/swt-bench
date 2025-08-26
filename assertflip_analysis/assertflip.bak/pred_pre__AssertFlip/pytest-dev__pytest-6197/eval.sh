#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD e856638ba086fcf5bebf1bebea32d5cf78de87b4 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff e856638ba086fcf5bebf1bebea32d5cf78de87b4
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/testing/test_coverup_pytest-dev__pytest-6197.py
new file mode 100644
index e69de29..37f4a3e 100644
--- /dev/null
+++ b/testing/test_coverup_pytest-dev__pytest-6197.py
@@ -0,0 +1,21 @@
+import os
+import pytest
+import tempfile
+
+def test_pytest_collects_init_py():
+    # Create a temporary directory
+    with tempfile.TemporaryDirectory() as temp_dir:
+        # Create a subdirectory named 'foobar'
+        foobar_dir = os.path.join(temp_dir, 'foobar')
+        os.mkdir(foobar_dir)
+
+        # Create an __init__.py file with 'assert False' in the 'foobar' directory
+        init_file_path = os.path.join(foobar_dir, '__init__.py')
+        with open(init_file_path, 'w') as f:
+            f.write('assert False\n')
+
+        # Run pytest on the temporary directory
+        result = pytest.main([foobar_dir])
+
+        # Assert that pytest returns a zero exit code, indicating no error
+        assert result == 0

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/python\.py)' -m pytest -rA testing/test_coverup_pytest-dev__pytest-6197.py
cat coverage.cover
git checkout e856638ba086fcf5bebf1bebea32d5cf78de87b4
git apply /root/pre_state.patch
