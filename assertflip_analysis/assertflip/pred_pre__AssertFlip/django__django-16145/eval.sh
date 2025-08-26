#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 93d4c9ea1de24eb391cb2b3561b6703fd46374df >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 93d4c9ea1de24eb391cb2b3561b6703fd46374df
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16145.py
new file mode 100644
index e69de29..11abd1d 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16145.py
@@ -0,0 +1,19 @@
+from django.test import TestCase
+from django.core.management import call_command
+from io import StringIO
+from unittest.mock import patch
+
+class RunserverShorthandIPTest(TestCase):
+    def test_runserver_shorthand_ip_output(self):
+        """
+        Test that running 'runserver 0:8000' outputs "Starting development server at http://0.0.0.0:8000/"
+        as expected.
+        """
+        out = StringIO()
+        with patch('sys.stdout', new=out):
+            # Mock the run function to prevent actual server start
+            with patch('django.core.servers.basehttp.run', return_value=None):
+                call_command('runserver', '0:8000', use_reloader=False)
+        
+        output = out.getvalue()
+        self.assertIn("Starting development server at http://0.0.0.0:8000/", output)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/core/management/commands/runserver\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16145
cat coverage.cover
git checkout 93d4c9ea1de24eb391cb2b3561b6703fd46374df
git apply /root/pre_state.patch
