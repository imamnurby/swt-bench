#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a7e38c5c61928033a2dc1915cbee8caa8544a4d0 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a7e38c5c61928033a2dc1915cbee8caa8544a4d0
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/src/_pytest/pathlib.py b/src/_pytest/pathlib.py
--- a/src/_pytest/pathlib.py
+++ b/src/_pytest/pathlib.py
@@ -558,7 +558,7 @@ def visit(
     entries = sorted(os.scandir(path), key=lambda entry: entry.name)
     yield from entries
     for entry in entries:
-        if entry.is_dir(follow_symlinks=False) and recurse(entry):
+        if entry.is_dir() and recurse(entry):
             yield from visit(entry.path, recurse)
 
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/testing/test_coverup_pytest-dev__pytest-7982.py
new file mode 100644
index e69de29..c0b12c5 100644
--- /dev/null
+++ b/testing/test_coverup_pytest-dev__pytest-7982.py
@@ -0,0 +1,26 @@
+import os
+import pytest
+import tempfile
+
+def test_symlinked_directory_not_collected(capsys):
+    # Create a temporary directory structure
+    with tempfile.TemporaryDirectory() as tempdir:
+        # Create a target directory with a test file
+        target_dir = os.path.join(tempdir, 'target')
+        os.mkdir(target_dir)
+        test_file = os.path.join(target_dir, 'test_example.py')
+        with open(test_file, 'w') as f:
+            f.write('def test_example():\n    assert True\n')
+
+        # Create a symlink to the target directory
+        symlink_dir = os.path.join(tempdir, 'symlink')
+        os.symlink(target_dir, symlink_dir)
+
+        # Run pytest on the directory containing the symlink with --collect-only
+        pytest.main([tempdir, '--collect-only'])
+
+        # Capture the output
+        captured = capsys.readouterr()
+
+        # Assert that the test in the symlinked directory is collected
+        assert 'symlink/test_example.py' in captured.out

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(src/_pytest/pathlib\.py)' -m pytest -rA testing/test_coverup_pytest-dev__pytest-7982.py
cat coverage.cover
git checkout a7e38c5c61928033a2dc1915cbee8caa8544a4d0
git apply /root/pre_state.patch
