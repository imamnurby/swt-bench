#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD f0adf3b9b7a19cdee05368ff0c0c2d087f011180 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff f0adf3b9b7a19cdee05368ff0c0c2d087f011180
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11848.py
new file mode 100644
index e69de29..1ce11cc 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11848.py
@@ -0,0 +1,22 @@
+from django.test import SimpleTestCase
+from django.utils.http import parse_http_date
+import datetime
+
+class ParseHttpDateTests(SimpleTestCase):
+    def test_parse_http_date_two_digit_year_bug(self):
+        # Test case: Year '74' should be interpreted as 2074 according to the correct logic
+        # Using RFC850_DATE format: 'Sunday, 06-Nov-74 08:49:37 GMT'
+        date_string = "Sunday, 06-Nov-74 08:49:37 GMT"
+        parsed_timestamp = parse_http_date(date_string)
+        parsed_year = datetime.datetime.utcfromtimestamp(parsed_timestamp).year
+
+        # Assert the correct behavior
+        self.assertEqual(parsed_year, 2074)  # Correct behavior: should be interpreted as 2074
+
+        # Test case: Year '50' should be interpreted as 1950 according to the correct logic
+        date_string = "Sunday, 06-Nov-50 08:49:37 GMT"
+        parsed_timestamp = parse_http_date(date_string)
+        parsed_year = datetime.datetime.utcfromtimestamp(parsed_timestamp).year
+
+        # Assert the correct behavior
+        self.assertEqual(parsed_year, 1950)  # Correct behavior: should be interpreted as 1950

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/utils/http\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11848
cat coverage.cover
git checkout f0adf3b9b7a19cdee05368ff0c0c2d087f011180
git apply /root/pre_state.patch
