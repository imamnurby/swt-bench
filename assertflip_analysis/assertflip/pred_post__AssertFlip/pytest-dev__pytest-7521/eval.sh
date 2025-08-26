#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 41d211c24a6781843b174379d6d6538f5c17adb9 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 41d211c24a6781843b174379d6d6538f5c17adb9
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/src/_pytest/capture.py b/src/_pytest/capture.py
--- a/src/_pytest/capture.py
+++ b/src/_pytest/capture.py
@@ -388,6 +388,7 @@ def __init__(self, targetfd: int) -> None:
                 TemporaryFile(buffering=0),  # type: ignore[arg-type]
                 encoding="utf-8",
                 errors="replace",
+                newline="",
                 write_through=True,
             )
             if targetfd in patchsysdict:

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/testing/test_coverup_pytest-dev__pytest-7521.py
new file mode 100644
index e69de29..4c46693 100644
--- /dev/null
+++ b/testing/test_coverup_pytest-dev__pytest-7521.py
@@ -0,0 +1,6 @@
+import pytest
+
+def test_capfd_includes_carriage_return(capfd):
+    print('Test string with carriage return', end='\r')
+    out, err = capfd.readouterr()
+    assert out.endswith('\r')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/capture\.py)' -m pytest -rA testing/test_coverup_pytest-dev__pytest-7521.py
cat coverage.cover
git checkout 41d211c24a6781843b174379d6d6538f5c17adb9
git apply /root/pre_state.patch
