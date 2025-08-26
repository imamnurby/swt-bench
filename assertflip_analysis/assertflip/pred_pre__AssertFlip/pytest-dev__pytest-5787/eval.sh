#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 955e54221008aba577ecbaefa15679f6777d3bf8 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 955e54221008aba577ecbaefa15679f6777d3bf8
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/testing/test_coverup_pytest-dev__pytest-5787.py
new file mode 100644
index e69de29..5f07119 100644
--- /dev/null
+++ b/testing/test_coverup_pytest-dev__pytest-5787.py
@@ -0,0 +1,55 @@
+import pytest
+from _pytest.reports import TestReport
+from _pytest._code.code import ExceptionInfo
+
+def test_chained_exception_serialization():
+    # Simulate a test item and call with chained exceptions
+    class FakeItem:
+        nodeid = "test_chained_exception"
+        location = ("test_file.py", 10, "test_chained_exception")
+        keywords = {}
+        user_properties = []
+        _report_sections = []
+
+        def repr_failure(self, excinfo):
+            return str(excinfo.value)
+
+        def _repr_failure_py(self, excinfo, style):
+            return str(excinfo.value)
+
+    class Call:
+        def __init__(self, when, excinfo):
+            self.when = when
+            self.excinfo = excinfo
+            self.stop = 1
+            self.start = 0
+
+    # Create a chained exception
+    try:
+        try:
+            raise ValueError(11)
+        except Exception as e1:
+            raise ValueError(12) from e1
+    except Exception as e2:
+        excinfo = ExceptionInfo.from_current()
+
+    # Create a test report with the exception
+    item = FakeItem()
+    call = Call("call", excinfo)
+    report = TestReport.from_item_and_call(item, call)
+
+    # Serialize the report using the function from the codebase
+    def pytest_report_to_serializable(report):
+        if isinstance(report, TestReport):
+            data = report._to_json()
+            data['_report_type'] = report.__class__.__name__
+            return data
+
+    serialized = pytest_report_to_serializable(report)
+
+    # Check if the serialized report contains the full exception chain
+    # This is the correct behavior we want to enforce
+    assert "12" in serialized['longrepr']
+    assert "11" in serialized['longrepr']
+
+    # The test will now fail if the full exception chain is not serialized

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/reports\.py)' -m pytest -rA testing/test_coverup_pytest-dev__pytest-5787.py
cat coverage.cover
git checkout 955e54221008aba577ecbaefa15679f6777d3bf8
git apply /root/pre_state.patch
