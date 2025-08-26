#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD bef6f7584280f1cc80e5e2d80b7ad073a93d26ec >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff bef6f7584280f1cc80e5e2d80b7ad073a93d26ec
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13809.py
new file mode 100644
index e69de29..b8e9b48 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13809.py
@@ -0,0 +1,22 @@
+from django.test import TestCase
+from django.core.management import call_command
+from io import StringIO
+
+class RunserverCommandTests(TestCase):
+    def test_runserver_skip_checks_option(self):
+        """
+        Test that the --skip-checks option is recognized by the runserver command.
+        This test should fail if the --skip-checks option is not implemented.
+        """
+        out = StringIO()
+        try:
+            call_command('runserver', '--skip-checks', stdout=out)
+        except SystemExit as e:
+            # The command should not exit with an error code because --skip-checks should be recognized
+            self.assertEqual(e.code, 0)
+        except Exception as e:
+            # If any other exception occurs, it indicates the option is not recognized
+            self.fail(f"Unexpected exception raised: {e}")
+        else:
+            # If no exception occurs, it means the option is recognized and the test should pass
+            pass

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/core/management/commands/runserver\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13809
cat coverage.cover
git checkout bef6f7584280f1cc80e5e2d80b7ad073a93d26ec
git apply /root/pre_state.patch
