#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 350123f38c2b6217c38d70bfbd924a9ba3df1289 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 350123f38c2b6217c38d70bfbd924a9ba3df1289
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11749.py
new file mode 100644
index e69de29..da4f33f 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11749.py
@@ -0,0 +1,35 @@
+from django.core.management import call_command, CommandError
+from django.core.management.base import BaseCommand
+from django.test import SimpleTestCase
+from io import StringIO
+import sys
+
+class MyCommand(BaseCommand):
+    help = 'Test command for mutually exclusive group'
+
+    def add_arguments(self, parser):
+        shop_group = parser.add_mutually_exclusive_group(required=True)
+        shop_group.add_argument('--shop-id', nargs='?', type=int, default=None, dest='shop_id')
+        shop_group.add_argument('--shop', nargs='?', type=str, default=None, dest='shop_name')
+
+    def handle(self, *args, **options):
+        if options['shop_id']:
+            self.stdout.write(f"Shop ID: {options['shop_id']}")
+        elif options['shop_name']:
+            self.stdout.write(f"Shop Name: {options['shop_name']}")
+        else:
+            raise CommandError("One of the arguments --shop-id --shop is required")
+
+class CallCommandTest(SimpleTestCase):
+    def test_call_command_with_kwargs_in_mutually_exclusive_group(self):
+        """
+        Test that call_command correctly handles a required mutually exclusive group
+        argument passed via kwargs.
+        """
+        out = StringIO()
+        sys.stdout = out
+        try:
+            call_command(MyCommand(), shop_id=1)
+            self.assertIn("Shop ID: 1", out.getvalue())
+        finally:
+            sys.stdout = sys.__stdout__

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/core/management/__init__\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11749
cat coverage.cover
git checkout 350123f38c2b6217c38d70bfbd924a9ba3df1289
git apply /root/pre_state.patch
