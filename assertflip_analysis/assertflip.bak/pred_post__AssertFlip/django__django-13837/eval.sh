#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 415f50298f97fb17f841a9df38d995ccf347dfcc >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 415f50298f97fb17f841a9df38d995ccf347dfcc
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/utils/autoreload.py b/django/utils/autoreload.py
--- a/django/utils/autoreload.py
+++ b/django/utils/autoreload.py
@@ -216,14 +216,14 @@ def get_child_arguments():
     executable is reported to not have the .exe extension which can cause bugs
     on reloading.
     """
-    import django.__main__
-    django_main_path = Path(django.__main__.__file__)
+    import __main__
     py_script = Path(sys.argv[0])
 
     args = [sys.executable] + ['-W%s' % o for o in sys.warnoptions]
-    if py_script == django_main_path:
-        # The server was started with `python -m django runserver`.
-        args += ['-m', 'django']
+    # __spec__ is set when the server was started with the `-m` option,
+    # see https://docs.python.org/3/reference/import.html#main-spec
+    if __main__.__spec__ is not None and __main__.__spec__.parent:
+        args += ['-m', __main__.__spec__.parent]
         args += sys.argv[1:]
     elif not py_script.exists():
         # sys.argv[0] may not exist for several reasons on Windows.

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13837.py
new file mode 100644
index e69de29..6e884dc 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13837.py
@@ -0,0 +1,22 @@
+from django.test import SimpleTestCase
+from unittest.mock import patch
+import sys
+import types
+
+class GetChildArgumentsTest(SimpleTestCase):
+    def test_get_child_arguments_with_other_package(self):
+        # Mock sys.argv to simulate `python -m some_other_package runserver`
+        mock_argv = ['/path/to/some_other_package/__main__.py', 'runserver']
+        
+        # Mock __main__.__spec__ to simulate the presence of a package
+        mock_spec = types.SimpleNamespace(parent='some_other_package')
+
+        with patch.object(sys, 'argv', mock_argv):
+            with patch('django.__main__.__spec__', mock_spec):
+                with patch('django.__main__.__file__', '/path/to/some_other_package/__main__.py'):
+                    from django.utils.autoreload import get_child_arguments
+                    args = get_child_arguments()
+
+                    # Assert that the correct behavior occurs
+                    # The arguments should include '-m some_other_package'
+                    self.assertIn('-m some_other_package', args)  # This should be the correct behavior once the bug is fixed

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/utils/autoreload\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13837
cat coverage.cover
git checkout 415f50298f97fb17f841a9df38d995ccf347dfcc
git apply /root/pre_state.patch
