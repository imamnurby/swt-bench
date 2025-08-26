#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 98f6ada0e2058d67d91fb6c16482411ec2ca0967 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 98f6ada0e2058d67d91fb6c16482411ec2ca0967
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/template/defaultfilters.py b/django/template/defaultfilters.py
--- a/django/template/defaultfilters.py
+++ b/django/template/defaultfilters.py
@@ -444,6 +444,16 @@ def escape_filter(value):
     return conditional_escape(value)
 
 
+@register.filter(is_safe=True)
+def escapeseq(value):
+    """
+    An "escape" filter for sequences. Mark each element in the sequence,
+    individually, as a string that should be auto-escaped. Return a list with
+    the results.
+    """
+    return [conditional_escape(obj) for obj in value]
+
+
 @register.filter(is_safe=True)
 @stringfilter
 def force_escape(value):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16877.py
new file mode 100644
index e69de29..3a1f315 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16877.py
@@ -0,0 +1,23 @@
+from django.test import SimpleTestCase
+from django.template import Context, Template
+from django.utils.html import escape
+
+class EscapeseqFilterTests(SimpleTestCase):
+    def test_escapeseq_filter_with_join(self):
+        # Test input: list of strings that require escaping
+        input_list = ["<script>", "&", "\"quote\""]
+        delimiter = ","
+
+        # Expected output: each item should be escaped and then joined
+        expected_output = escape("<script>") + delimiter + escape("&") + delimiter + escape("\"quote\"")
+
+        # Template rendering with escapeseq and join filters
+        template_string = '{{ input_list|escapeseq|join:delimiter }}'
+        template = Template(template_string)
+        context = Context({'input_list': input_list, 'delimiter': delimiter})
+
+        # Render the template
+        output = template.render(context)
+
+        # Assert that the output is as expected
+        self.assertEqual(output, expected_output)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/template/defaultfilters\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16877
cat coverage.cover
git checkout 98f6ada0e2058d67d91fb6c16482411ec2ca0967
git apply /root/pre_state.patch
