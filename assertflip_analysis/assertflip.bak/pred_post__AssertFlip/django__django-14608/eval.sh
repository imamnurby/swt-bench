#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 7f33c1e22dbc34a7afae7967783725b10f1f13b1 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 7f33c1e22dbc34a7afae7967783725b10f1f13b1
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/forms/formsets.py b/django/forms/formsets.py
--- a/django/forms/formsets.py
+++ b/django/forms/formsets.py
@@ -333,7 +333,7 @@ def full_clean(self):
         self._non_form_errors.
         """
         self._errors = []
-        self._non_form_errors = self.error_class()
+        self._non_form_errors = self.error_class(error_class='nonform')
         empty_forms_count = 0
 
         if not self.is_bound:  # Stop further processing.
@@ -380,7 +380,10 @@ def full_clean(self):
             # Give self.clean() a chance to do cross-form validation.
             self.clean()
         except ValidationError as e:
-            self._non_form_errors = self.error_class(e.error_list)
+            self._non_form_errors = self.error_class(
+                e.error_list,
+                error_class='nonform'
+            )
 
     def clean(self):
         """

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14608.py
new file mode 100644
index e69de29..fd0e62a 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14608.py
@@ -0,0 +1,32 @@
+from django import forms
+from django.test import SimpleTestCase
+from django.forms import formset_factory, BaseFormSet, ValidationError
+from django.forms.utils import ErrorList
+
+class CustomErrorList(ErrorList):
+    def __init__(self, initlist=None, error_class=None):
+        super().__init__(initlist, error_class='nonform')
+
+class SimpleForm(forms.Form):
+    field = forms.CharField()
+
+class CustomFormSet(BaseFormSet):
+    def clean(self):
+        # Simulate a non-form error
+        raise ValidationError('Non-form error')
+
+class FormSetNonFormErrorsTest(SimpleTestCase):
+    def test_nonform_css_class_presence(self):
+        TestFormSet = formset_factory(SimpleForm, formset=CustomFormSet, extra=1)
+        formset_data = {
+            'form-TOTAL_FORMS': '1',
+            'form-INITIAL_FORMS': '0',
+            'form-MIN_NUM_FORMS': '0',
+            'form-MAX_NUM_FORMS': '1000',
+            'form-0-field': '',  # This will trigger a non-form error
+        }
+        formset = TestFormSet(data=formset_data)
+        formset.is_valid()  # Trigger full_clean and error processing
+
+        non_form_errors = formset.non_form_errors()
+        self.assertIn('nonform', non_form_errors.error_class)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/forms/formsets\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14608
cat coverage.cover
git checkout 7f33c1e22dbc34a7afae7967783725b10f1f13b1
git apply /root/pre_state.patch
