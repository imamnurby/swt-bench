#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 6a5ef557f80a8eb6a758ebe99c8bb477ca47459e >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 6a5ef557f80a8eb6a758ebe99c8bb477ca47459e
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/utils/html.py b/django/utils/html.py
--- a/django/utils/html.py
+++ b/django/utils/html.py
@@ -283,8 +283,9 @@ def trim_punctuation(lead, middle, trail):
             middle_unescaped = html.unescape(middle)
             stripped = middle_unescaped.rstrip(TRAILING_PUNCTUATION_CHARS)
             if middle_unescaped != stripped:
-                trail = middle[len(stripped):] + trail
-                middle = middle[:len(stripped) - len(middle_unescaped)]
+                punctuation_count = len(middle_unescaped) - len(stripped)
+                trail = middle[-punctuation_count:] + trail
+                middle = middle[:-punctuation_count]
                 trimmed_something = True
         return lead, middle, trail
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14539.py
new file mode 100644
index e69de29..b627ea1 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14539.py
@@ -0,0 +1,13 @@
+from django.test import SimpleTestCase
+from django.utils.html import urlize
+
+class UrlizeBugTest(SimpleTestCase):
+    def test_urlize_with_html_escaped_and_trailing_punctuation(self):
+        input_text = 'Search for google.com/?q=1&lt! and see.'
+        expected_correct_output = 'Search for <a href="http://google.com/?q=1%3C">google.com/?q=1&lt</a>! and see.'
+        
+        # Call the urlize function with the test input
+        actual_output = urlize(input_text)
+        
+        # Assert that the output matches the expected correct behavior
+        self.assertEqual(actual_output, expected_correct_output)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/utils/html\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14539
cat coverage.cover
git checkout 6a5ef557f80a8eb6a758ebe99c8bb477ca47459e
git apply /root/pre_state.patch
