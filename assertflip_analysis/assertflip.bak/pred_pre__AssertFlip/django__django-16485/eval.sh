#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 39f83765e12b0e5d260b7939fc3fe281d879b279 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 39f83765e12b0e5d260b7939fc3fe281d879b279
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16485.py
new file mode 100644
index e69de29..b614abe 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16485.py
@@ -0,0 +1,13 @@
+from decimal import Decimal
+from django.test import SimpleTestCase
+from django.template.defaultfilters import floatformat
+
+class FloatFormatBugTest(SimpleTestCase):
+    def test_floatformat_with_zero_decimal(self):
+        # Test with string '0.00'
+        result = floatformat('0.00', 0)
+        self.assertEqual(result, '0')
+
+        # Test with Decimal('0.00')
+        result = floatformat(Decimal('0.00'), 0)
+        self.assertEqual(result, '0')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/template/defaultfilters\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16485
cat coverage.cover
git checkout 39f83765e12b0e5d260b7939fc3fe281d879b279
git apply /root/pre_state.patch
