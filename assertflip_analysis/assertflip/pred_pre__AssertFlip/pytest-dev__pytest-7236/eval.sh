#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD c98bc4cd3d687fe9b392d8eecd905627191d4f06 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff c98bc4cd3d687fe9b392d8eecd905627191d4f06
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/testing/test_coverup_pytest-dev__pytest-7236.py
new file mode 100644
index e69de29..e3628ad 100644
--- /dev/null
+++ b/testing/test_coverup_pytest-dev__pytest-7236.py
@@ -0,0 +1,32 @@
+import pytest
+import unittest
+
+class MyTestCase(unittest.TestCase):
+    def setUp(self):
+        pass
+
+    @unittest.skip("hello")
+    def test_one(self):
+        pass
+
+    def tearDown(self):
+        # This will raise an error if executed, which should not happen for a skipped test
+        xxx
+
+def test_teardown_executed_on_skipped_test_with_pdb(monkeypatch):
+    # Create an instance of the test case
+    test_case = MyTestCase('test_one')
+
+    # Simulate the --pdb option by setting the _explicit_tearDown attribute
+    test_case._explicit_tearDown = test_case.tearDown
+    setattr(test_case, 'tearDown', lambda *args: None)
+
+    # Manually call the _explicit_tearDown to simulate the bug
+    try:
+        test_case._explicit_tearDown()
+    except NameError:
+        # If an exception is raised, the test should fail
+        assert False, "tearDown should not be executed for a skipped test"
+    else:
+        # If no exception is raised, the test passes because the bug is fixed
+        pass

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/unittest\.py)' -m pytest -rA testing/test_coverup_pytest-dev__pytest-7236.py
cat coverage.cover
git checkout c98bc4cd3d687fe9b392d8eecd905627191d4f06
git apply /root/pre_state.patch
