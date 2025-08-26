#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 8c0886b068ba4e224dd78104b93c9638b860b398 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 8c0886b068ba4e224dd78104b93c9638b860b398
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/utils/formats.py b/django/utils/formats.py
--- a/django/utils/formats.py
+++ b/django/utils/formats.py
@@ -113,6 +113,7 @@ def get_format(format_type, lang=None, use_l10n=None):
             use_l10n = settings.USE_L10N
     if use_l10n and lang is None:
         lang = get_language()
+    format_type = str(format_type)  # format_type may be lazy.
     cache_key = (format_type, lang)
     try:
         return _format_cache[cache_key]

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15741.py
new file mode 100644
index e69de29..2c0a927 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15741.py
@@ -0,0 +1,21 @@
+from django.test import SimpleTestCase
+from django.utils.functional import lazy
+from django.template.defaultfilters import date
+from datetime import datetime
+
+class DateFilterLazyStringTest(SimpleTestCase):
+    def test_date_filter_with_lazy_string(self):
+        # Create a lazy string using Django's lazy utility
+        lazy_format = lazy(lambda: 'Y-m-d', str)()
+
+        # Create a sample date
+        sample_date = datetime(2023, 10, 5)
+
+        # Attempt to use the date filter with a lazy string
+        try:
+            result = date(sample_date, lazy_format)
+            # Assert that the result is as expected when the bug is fixed
+            self.assertEqual(result, '2023-10-05', "BUG: Date filter did not process lazy string correctly.")
+        except TypeError as e:
+            # If a TypeError is raised, assert False to indicate the bug
+            self.assertFalse(True, f"BUG: Unexpected TypeError raised: {str(e)}")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/utils/formats\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15741
cat coverage.cover
git checkout 8c0886b068ba4e224dd78104b93c9638b860b398
git apply /root/pre_state.patch
