#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD aa55975c7d3f6c9f6d7f68accc41bb7cadf0eb9a >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff aa55975c7d3f6c9f6d7f68accc41bb7cadf0eb9a
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/testing/test_coverup_pytest-dev__pytest-10051.py
new file mode 100644
index e69de29..00306f7 100644
--- /dev/null
+++ b/testing/test_coverup_pytest-dev__pytest-10051.py
@@ -0,0 +1,22 @@
+import logging
+import pytest
+
+def test_caplog_clear_bug(caplog):
+    def verify_consistency():
+        # Assert that caplog.get_records("call") and caplog.records are the same
+        assert caplog.get_records("call") == caplog.records
+
+    # Initial consistency check
+    verify_consistency()
+
+    # Log a message
+    logging.warning("test")
+
+    # Consistency check after logging
+    verify_consistency()
+
+    # Clear the logs
+    caplog.clear()
+
+    # Consistency check after clear
+    verify_consistency()

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/logging\.py)' -m pytest -rA testing/test_coverup_pytest-dev__pytest-10051.py
cat coverage.cover
git checkout aa55975c7d3f6c9f6d7f68accc41bb7cadf0eb9a
git apply /root/pre_state.patch
