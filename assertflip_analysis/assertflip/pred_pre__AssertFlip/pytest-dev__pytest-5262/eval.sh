#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 58e6a09db49f34886ff13f3b7520dd0bcd7063cd >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 58e6a09db49f34886ff13f3b7520dd0bcd7063cd
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/testing/test_coverup_pytest-dev__pytest-5262.py
new file mode 100644
index e69de29..f42407e 100644
--- /dev/null
+++ b/testing/test_coverup_pytest-dev__pytest-5262.py
@@ -0,0 +1,19 @@
+import pytest
+from _pytest.capture import EncodedFile
+import six
+
+def test_encoded_file_write_bytes():
+    # Create a mock buffer to simulate the file
+    class MockBuffer:
+        def write(self, obj):
+            # Simulate writing to a buffer
+            pass
+
+    # Create an instance of EncodedFile with a mock buffer
+    buffer = MockBuffer()
+    encoded_file = EncodedFile(buffer, 'utf-8')
+
+    # Attempt to write bytes to the EncodedFile
+    # This should raise an exception due to the bug
+    with pytest.raises(TypeError, match="write() argument must be str, not bytes"):
+        encoded_file.write(b"test bytes")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/capture\.py)' -m pytest -rA testing/test_coverup_pytest-dev__pytest-5262.py
cat coverage.cover
git checkout 58e6a09db49f34886ff13f3b7520dd0bcd7063cd
git apply /root/pre_state.patch
