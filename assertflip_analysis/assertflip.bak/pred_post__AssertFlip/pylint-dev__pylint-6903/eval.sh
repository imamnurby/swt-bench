#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD ca80f03a43bc39e4cc2c67dc99817b3c9f13b8a6 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff ca80f03a43bc39e4cc2c67dc99817b3c9f13b8a6
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/pylint/lint/run.py b/pylint/lint/run.py
--- a/pylint/lint/run.py
+++ b/pylint/lint/run.py
@@ -58,6 +58,13 @@ def _query_cpu() -> int | None:
             cpu_shares = int(file.read().rstrip())
         # For AWS, gives correct value * 1024.
         avail_cpu = int(cpu_shares / 1024)
+
+    # In K8s Pods also a fraction of a single core could be available
+    # As multiprocessing is not able to run only a "fraction" of process
+    # assume we have 1 CPU available
+    if avail_cpu == 0:
+        avail_cpu = 1
+
     return avail_cpu
 
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_pylint-dev__pylint-6903.py
new file mode 100644
index e69de29..6933e91 100644
--- /dev/null
+++ b/tests/test_coverup_pylint-dev__pylint-6903.py
@@ -0,0 +1,27 @@
+import pytest
+import multiprocessing
+from unittest import mock
+from pylint.lint.run import _query_cpu
+
+def mock_open(read_data):
+    m = mock.mock_open(read_data=read_data)
+    m.return_value.__iter__ = lambda self: iter(self.readline, '')
+    return m
+
+def test_query_cpu_returns_non_zero(monkeypatch):
+    # Mock the file reads to simulate the conditions that lead to the bug
+    with mock.patch('builtins.open', mock_open(read_data='-1')) as mock_file:
+        with mock.patch('pathlib.Path.is_file', return_value=True):
+            # Call the function that triggers the bug
+            cpu_count = _query_cpu()
+            
+            # Assert that _query_cpu() does not return 0
+            assert cpu_count != 0, "BUG: _query_cpu() should not return 0"
+
+            # Attempt to initialize multiprocessing.Pool with the returned value
+            # This should not raise an error if the bug is fixed
+            try:
+                multiprocessing.Pool(cpu_count)
+            except ValueError as e:
+                pytest.fail(f"BUG: multiprocessing.Pool raised ValueError: {e}")
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(pylint/lint/run\.py)' -m pytest --no-header -rA  -p no:cacheprovider tests/test_coverup_pylint-dev__pylint-6903.py
cat coverage.cover
git checkout ca80f03a43bc39e4cc2c67dc99817b3c9f13b8a6
git apply /root/pre_state.patch
