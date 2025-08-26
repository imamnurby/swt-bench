#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 37c5b8c07be104fd5288cd87f101e48cb7a40298 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 37c5b8c07be104fd5288cd87f101e48cb7a40298
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/template/defaultfilters.py b/django/template/defaultfilters.py
--- a/django/template/defaultfilters.py
+++ b/django/template/defaultfilters.py
@@ -149,7 +149,7 @@ def floatformat(text, arg=-1):
             use_l10n = False
             arg = arg[:-1] or -1
     try:
-        input_val = repr(text)
+        input_val = str(text)
         d = Decimal(input_val)
     except InvalidOperation:
         try:

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15863.py
new file mode 100644
index e69de29..0845fc3 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15863.py
@@ -0,0 +1,32 @@
+from decimal import Decimal
+from django.test import SimpleTestCase
+from django.template import Template, Context
+from django.conf import settings
+from django import setup
+
+class FloatFormatPrecisionTest(SimpleTestCase):
+    @classmethod
+    def setUpClass(cls):
+        super().setUpClass()
+        # Configure Django settings for template rendering
+        TEMPLATES = [
+            {
+                'BACKEND': 'django.template.backends.django.DjangoTemplates',
+            },
+        ]
+        if not settings.configured:
+            settings.configure(TEMPLATES=TEMPLATES)
+        setup()
+
+    def test_floatformat_precision_loss(self):
+        # Create a template using the floatformat filter with high precision
+        template = Template('{{ value|floatformat:20 }}')
+        
+        # Use a Decimal number with high precision
+        context = Context({'value': Decimal('42.12345678901234567890')})
+        
+        # Render the template
+        rendered = template.render(context)
+        
+        # Assert that the rendered output matches the correct output
+        self.assertEqual(rendered, '42.12345678901234567890')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/template/defaultfilters\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15863
cat coverage.cover
git checkout 37c5b8c07be104fd5288cd87f101e48cb7a40298
git apply /root/pre_state.patch
