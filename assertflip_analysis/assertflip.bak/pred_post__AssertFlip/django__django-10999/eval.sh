#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 36300ef336e3f130a0dadc1143163ff3d23dc843 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 36300ef336e3f130a0dadc1143163ff3d23dc843
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/utils/dateparse.py b/django/utils/dateparse.py
--- a/django/utils/dateparse.py
+++ b/django/utils/dateparse.py
@@ -29,9 +29,10 @@
 standard_duration_re = re.compile(
     r'^'
     r'(?:(?P<days>-?\d+) (days?, )?)?'
-    r'((?:(?P<hours>-?\d+):)(?=\d+:\d+))?'
-    r'(?:(?P<minutes>-?\d+):)?'
-    r'(?P<seconds>-?\d+)'
+    r'(?P<sign>-?)'
+    r'((?:(?P<hours>\d+):)(?=\d+:\d+))?'
+    r'(?:(?P<minutes>\d+):)?'
+    r'(?P<seconds>\d+)'
     r'(?:\.(?P<microseconds>\d{1,6})\d{0,6})?'
     r'$'
 )

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-10999.py
new file mode 100644
index e69de29..0a81828 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-10999.py
@@ -0,0 +1,31 @@
+from django.test import SimpleTestCase
+from django.utils.dateparse import parse_duration
+import datetime
+
+class ParseDurationBugTest(SimpleTestCase):
+    def test_negative_duration_bug(self):
+        """
+        Test parse_duration with a negative duration string.
+        The function should correctly parse the duration once the bug is fixed.
+        """
+        result = parse_duration("-1:00:00")
+        # The expected result should be a negative timedelta.
+        self.assertEqual(result, datetime.timedelta(hours=-1))  # The function should return correct timedelta
+
+    def test_negative_minutes_bug(self):
+        """
+        Test parse_duration with a negative minutes string.
+        The function should correctly parse the duration once the bug is fixed.
+        """
+        result = parse_duration("0:-30:00")
+        # The expected result should be a negative timedelta.
+        self.assertEqual(result, datetime.timedelta(minutes=-30))  # The function should return correct timedelta
+
+    def test_negative_seconds_bug(self):
+        """
+        Test parse_duration with a negative seconds string.
+        The function should correctly parse the duration once the bug is fixed.
+        """
+        result = parse_duration("0:00:-30")
+        # The expected result should be a negative timedelta.
+        self.assertEqual(result, datetime.timedelta(seconds=-30))  # The function should return correct timedelta

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/utils/dateparse\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-10999
cat coverage.cover
git checkout 36300ef336e3f130a0dadc1143163ff3d23dc843
git apply /root/pre_state.patch
