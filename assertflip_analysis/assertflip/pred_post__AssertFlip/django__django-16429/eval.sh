#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 6c86495bcee22eac19d7fb040b2988b830707cbd >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 6c86495bcee22eac19d7fb040b2988b830707cbd
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/utils/timesince.py b/django/utils/timesince.py
--- a/django/utils/timesince.py
+++ b/django/utils/timesince.py
@@ -97,6 +97,7 @@ def timesince(d, now=None, reversed=False, time_strings=None, depth=2):
             d.hour,
             d.minute,
             d.second,
+            tzinfo=d.tzinfo,
         )
     else:
         pivot = d

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16429.py
new file mode 100644
index e69de29..e49db2f 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16429.py
@@ -0,0 +1,18 @@
+from django.test import TestCase, override_settings
+from django.utils import timezone
+from django.utils.timesince import timesince
+import datetime
+
+class TimesinceTests(TestCase):
+    @override_settings(USE_TZ=True)
+    def test_timesince_with_long_interval_and_tz(self):
+        """
+        Test timesince with a datetime object that's one month (or more) in the past
+        with USE_TZ=True. This should correctly calculate the time difference without
+        raising a TypeError.
+        """
+        now = timezone.now()
+        # Create a naive datetime object 31 days in the past
+        d = now - datetime.timedelta(days=31)
+        # Call timesince and expect it to return "1 month" without raising an error
+        self.assertEqual(timesince(d), "1\xa0month")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/utils/timesince\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16429
cat coverage.cover
git checkout 6c86495bcee22eac19d7fb040b2988b830707cbd
git apply /root/pre_state.patch
