#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD e6e300e729dd33956e5448d8be9a0b1540b4e53a >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff e6e300e729dd33956e5448d8be9a0b1540b4e53a
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/src/_pytest/skipping.py b/src/_pytest/skipping.py
--- a/src/_pytest/skipping.py
+++ b/src/_pytest/skipping.py
@@ -291,7 +291,8 @@ def pytest_runtest_makereport(item: Item, call: CallInfo[None]):
             else:
                 rep.outcome = "passed"
                 rep.wasxfail = xfailed.reason
-    elif (
+
+    if (
         item._store.get(skipped_by_mark_key, True)
         and rep.skipped
         and type(rep.longrepr) is tuple

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/testing/test_coverup_pytest-dev__pytest-7432.py
new file mode 100644
index e69de29..b58fa4d 100644
--- /dev/null
+++ b/testing/test_coverup_pytest-dev__pytest-7432.py
@@ -0,0 +1,25 @@
+import pytest
+import os
+
+def test_skip_location_reporting():
+    # Create a test file with a function marked with @pytest.mark.skip
+    test_file_content = """
+import pytest
+
+@pytest.mark.skip
+def test_skip_location():
+    assert 0
+"""
+    test_file_path = "test_skip_location.py"
+    with open(test_file_path, "w") as f:
+        f.write(test_file_content)
+
+    # Run the test with pytest -rs --runxfail and capture the output
+    result = pytest.main(["-rs", "--runxfail", test_file_path])
+
+    # Check that the skip location is correctly reported as test_skip_location.py:3
+    assert result != 0  # The test should fail if the bug is present
+
+    # Cleanup: remove the test file
+    os.remove(test_file_path)
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/skipping\.py)' -m pytest -rA testing/test_coverup_pytest-dev__pytest-7432.py
cat coverage.cover
git checkout e6e300e729dd33956e5448d8be9a0b1540b4e53a
git apply /root/pre_state.patch
