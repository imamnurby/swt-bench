#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 4884a87e022056eda10534c13d74e49b8cdda632 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 4884a87e022056eda10534c13d74e49b8cdda632
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/utils/autoreload.py b/django/utils/autoreload.py
--- a/django/utils/autoreload.py
+++ b/django/utils/autoreload.py
@@ -220,6 +220,11 @@ def get_child_arguments():
     py_script = Path(sys.argv[0])
 
     args = [sys.executable] + ['-W%s' % o for o in sys.warnoptions]
+    if sys.implementation.name == 'cpython':
+        args.extend(
+            f'-X{key}' if value is True else f'-X{key}={value}'
+            for key, value in sys._xoptions.items()
+        )
     # __spec__ is set when the server was started with the `-m` option,
     # see https://docs.python.org/3/reference/import.html#main-spec
     # __spec__ may not exist, e.g. when running in a Conda env.

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14771.py
new file mode 100644
index e69de29..69f07a0 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14771.py
@@ -0,0 +1,55 @@
+from django.test import SimpleTestCase
+import subprocess
+import os
+import time
+
+class AutoReloaderXOptionsTest(SimpleTestCase):
+    def test_auto_reloader_x_options(self):
+        """
+        Test that the auto-reloader correctly passes the -X utf8 option on Windows.
+        The test should fail if the bug is present, indicating incorrect behavior.
+        """
+        # Create a temporary manage.py file with a print statement for the encoding
+        manage_py_content = """
+import sys
+with open(__file__, mode="r") as stream:
+    print("=== %s" % stream.encoding)
+"""
+        with open('manage.py', 'w') as f:
+            f.write(manage_py_content)
+
+        # Run the Django server with the -X utf8 option and auto-reloader enabled
+        process = subprocess.Popen(
+            ['python', '-X', 'utf8', 'manage.py', 'runserver', '0.0.0.0:8005', '-v3'],
+            stdout=subprocess.PIPE,
+            stderr=subprocess.PIPE,
+            text=True
+        )
+
+        # Allow some time for the server to start
+        time.sleep(5)
+
+        # Capture the initial output
+        stdout, stderr = process.communicate(timeout=10)
+
+        # Check if the initial output contains 'UTF-8'
+        initial_encoding = '=== utf-8' in stdout
+
+        # Modify the manage.py file to trigger the auto-reloader
+        with open('manage.py', 'a') as f:
+            f.write("# Trigger reload\n")
+
+        # Allow some time for the reload to occur
+        time.sleep(5)
+
+        # Capture the output after reload
+        stdout, stderr = process.communicate(timeout=10)
+
+        # Check if the output after reload contains 'utf-8', which indicates the bug is present
+        reload_encoding_bug = '=== utf-8' in stdout
+
+        # Assert that the encoding does not remain 'utf-8', indicating the bug
+        self.assertFalse(initial_encoding and reload_encoding_bug)
+
+        # Cleanup: remove the manage.py file
+        os.remove('manage.py')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/utils/autoreload\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14771
cat coverage.cover
git checkout 4884a87e022056eda10534c13d74e49b8cdda632
git apply /root/pre_state.patch
