#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 3c1534944cbd34e8a41bc9e76818018fadefc9a1 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 3c1534944cbd34e8a41bc9e76818018fadefc9a1
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/testing/test_coverup_pytest-dev__pytest-10356.py
new file mode 100644
index e69de29..80e80a2 100644
--- /dev/null
+++ b/testing/test_coverup_pytest-dev__pytest-10356.py
@@ -0,0 +1,27 @@
+import pytest
+
+# Define two base classes with different markers
+@pytest.mark.foo
+class Foo:
+    pass
+
+@pytest.mark.bar
+class Bar:
+    pass
+
+# Derived class inheriting from both base classes
+class TestDings(Foo, Bar):
+    def test_dings(self):
+        pass
+
+def test_dings_markers():
+    # Retrieve the markers on the TestDings class
+    markers = getattr(TestDings, 'pytestmark', [])
+
+    # Assert that both markers are present
+    assert len(markers) == 2, "Expected both 'foo' and 'bar' markers to be present"
+
+    # Assert that both 'foo' and 'bar' markers are present
+    marker_names = {marker.name for marker in markers}
+    assert 'foo' in marker_names, "Expected 'foo' marker to be present"
+    assert 'bar' in marker_names, "Expected 'bar' marker to be present"

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/mark/structures\.py)' -m pytest -rA testing/test_coverup_pytest-dev__pytest-10356.py
cat coverage.cover
git checkout 3c1534944cbd34e8a41bc9e76818018fadefc9a1
git apply /root/pre_state.patch
