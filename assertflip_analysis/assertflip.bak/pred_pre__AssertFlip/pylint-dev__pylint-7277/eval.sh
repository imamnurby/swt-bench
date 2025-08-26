#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 684a1d6aa0a6791e20078bc524f97c8906332390 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 684a1d6aa0a6791e20078bc524f97c8906332390
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_pylint-dev__pylint-7277.py
new file mode 100644
index e69de29..eff4750 100644
--- /dev/null
+++ b/tests/test_coverup_pylint-dev__pylint-7277.py
@@ -0,0 +1,22 @@
+import sys
+import os
+import pytest
+from pylint import modify_sys_path
+
+def test_modify_sys_path_removes_first_entry():
+    # Setup: Add a custom entry to the beginning of sys.path
+    original_sys_path = sys.path[:]
+    custom_entry = "something"
+    sys.path.insert(0, custom_entry)
+
+    # Precondition: Ensure the first entry is the custom entry
+    assert sys.path[0] == custom_entry
+
+    # Invoke the function that contains the bug
+    modify_sys_path()
+
+    # Assertion: The first entry should not be removed if it's not "", ".", or os.getcwd()
+    assert sys.path[0] == custom_entry
+
+    # Cleanup: Restore the original sys.path
+    sys.path = original_sys_path

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(pylint/__init__\.py)' -m pytest --no-header -rA  -p no:cacheprovider tests/test_coverup_pylint-dev__pylint-7277.py
cat coverage.cover
git checkout 684a1d6aa0a6791e20078bc524f97c8906332390
git apply /root/pre_state.patch
