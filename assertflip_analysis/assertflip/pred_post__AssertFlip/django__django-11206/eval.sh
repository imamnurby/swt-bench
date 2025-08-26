#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 571ab44e8a8936014c22e7eebe4948d9611fd7ce >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 571ab44e8a8936014c22e7eebe4948d9611fd7ce
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/utils/numberformat.py b/django/utils/numberformat.py
--- a/django/utils/numberformat.py
+++ b/django/utils/numberformat.py
@@ -27,6 +27,14 @@ def format(number, decimal_sep, decimal_pos=None, grouping=0, thousand_sep='',
     # sign
     sign = ''
     if isinstance(number, Decimal):
+
+        if decimal_pos is not None:
+            # If the provided number is too small to affect any of the visible
+            # decimal places, consider it equal to '0'.
+            cutoff = Decimal('0.' + '1'.rjust(decimal_pos, '0'))
+            if abs(number) < cutoff:
+                number = Decimal('0')
+
         # Format values with more than 200 digits (an arbitrary cutoff) using
         # scientific notation to avoid high memory usage in {:f}'.format().
         _, digits, exponent = number.as_tuple()

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11206.py
new file mode 100644
index e69de29..f789845 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11206.py
@@ -0,0 +1,16 @@
+from django.test import SimpleTestCase
+from decimal import Decimal
+from django.utils.numberformat import format as nformat
+
+class NumberFormatBugTest(SimpleTestCase):
+    def test_format_small_decimal_exponential_notation(self):
+        # Test input: very small decimal number
+        number = Decimal('1e-200')
+        decimal_sep = '.'
+        decimal_pos = 2
+
+        # Call the format function to trigger the bug
+        result = nformat(number, decimal_sep, decimal_pos)
+
+        # Assert the correct behavior should occur
+        self.assertEqual(result, '0.00')  # The expected correct behavior

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/utils/numberformat\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11206
cat coverage.cover
git checkout 571ab44e8a8936014c22e7eebe4948d9611fd7ce
git apply /root/pre_state.patch
