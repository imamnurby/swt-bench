#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD c448e614c60cc97c6194c62052363f4f501e0953 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff c448e614c60cc97c6194c62052363f4f501e0953
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13670.py
new file mode 100644
index e69de29..2bf18fb 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13670.py
@@ -0,0 +1,14 @@
+from django.test import SimpleTestCase
+from django.utils import dateformat
+import datetime
+
+class DateFormatYearTest(SimpleTestCase):
+    def test_year_format_bug(self):
+        # Create a datetime object with a year less than 1000
+        dt = datetime.datetime(123, 4, 5)
+        
+        # Format using dateformat with 'y' character
+        formatted_year = dateformat.format(dt, "y")
+        
+        # Assert the correct behavior: expecting two digits with leading zero
+        self.assertEqual(formatted_year, '23')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/utils/dateformat\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13670
cat coverage.cover
git checkout c448e614c60cc97c6194c62052363f4f501e0953
git apply /root/pre_state.patch
