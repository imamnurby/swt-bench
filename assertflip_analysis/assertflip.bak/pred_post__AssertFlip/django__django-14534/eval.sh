#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 910ecd1b8df7678f45c3d507dde6bcb1faafa243 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 910ecd1b8df7678f45c3d507dde6bcb1faafa243
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/forms/boundfield.py b/django/forms/boundfield.py
--- a/django/forms/boundfield.py
+++ b/django/forms/boundfield.py
@@ -277,7 +277,7 @@ def template_name(self):
 
     @property
     def id_for_label(self):
-        return 'id_%s_%s' % (self.data['name'], self.data['index'])
+        return self.data['attrs'].get('id')
 
     @property
     def choice_label(self):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14534.py
new file mode 100644
index e69de29..6a4b7ae 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14534.py
@@ -0,0 +1,26 @@
+from django import forms
+from django.test import SimpleTestCase
+
+class TestForm(forms.Form):
+    choices = forms.MultipleChoiceField(
+        widget=forms.CheckboxSelectMultiple,
+        choices=[('1', 'Option 1'), ('2', 'Option 2')]
+    )
+
+class BoundWidgetIdForLabelTest(SimpleTestCase):
+    def test_id_for_label_uses_custom_id_format(self):
+        # Create a form with a custom auto_id format
+        form = TestForm(auto_id='custom_id_%s')
+        
+        # Render the form to generate BoundWidget instances
+        rendered_form = form.as_p()
+        
+        # Access the BoundWidget instances for the CheckboxSelectMultiple widget
+        subwidgets = form['choices'].subwidgets
+        
+        # Iterate over the BoundWidget instances and call id_for_label
+        for widget in subwidgets:
+            id_for_label = widget.id_for_label
+            
+            # Assert that the id_for_label method returns the custom ID format
+            self.assertTrue(id_for_label.startswith('custom_id_'))

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/forms/boundfield\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14534
cat coverage.cover
git checkout 910ecd1b8df7678f45c3d507dde6bcb1faafa243
git apply /root/pre_state.patch
