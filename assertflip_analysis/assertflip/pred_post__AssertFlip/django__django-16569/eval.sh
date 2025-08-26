#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 278881e37619278789942513916acafaa88d26f3 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 278881e37619278789942513916acafaa88d26f3
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/forms/formsets.py b/django/forms/formsets.py
--- a/django/forms/formsets.py
+++ b/django/forms/formsets.py
@@ -490,7 +490,9 @@ def add_fields(self, form, index):
                     required=False,
                     widget=self.get_ordering_widget(),
                 )
-        if self.can_delete and (self.can_delete_extra or index < initial_form_count):
+        if self.can_delete and (
+            self.can_delete_extra or (index is not None and index < initial_form_count)
+        ):
             form.fields[DELETION_FIELD_NAME] = BooleanField(
                 label=_("Delete"),
                 required=False,

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16569.py
new file mode 100644
index e69de29..09b3f53 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16569.py
@@ -0,0 +1,32 @@
+from django import forms
+from django.test import SimpleTestCase
+from django.conf import settings
+from django.forms import formset_factory
+
+# Ensure settings are configured only once
+if not settings.configured:
+    settings.configure(
+        DEBUG=True,
+        MIDDLEWARE_CLASSES=[],
+        ROOT_URLCONF=__name__,
+    )
+
+class MyForm(forms.Form):
+    my_field = forms.CharField()
+
+class FormsetAddFieldsTest(SimpleTestCase):
+    def test_add_fields_with_none_index(self):
+        # Create a FormSet with can_delete=True and can_delete_extra=False
+        MyFormSet = formset_factory(
+            form=MyForm,
+            can_delete=True,
+            can_delete_extra=False,
+        )
+        my_formset = MyFormSet(initial=None)
+
+        try:
+            # Access the empty_form property to trigger the bug
+            _ = my_formset.empty_form
+        except TypeError as e:
+            # If a TypeError is raised, the test should fail
+            self.fail("TypeError raised: " + str(e))

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/forms/formsets\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16569
cat coverage.cover
git checkout 278881e37619278789942513916acafaa88d26f3
git apply /root/pre_state.patch
