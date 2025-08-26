#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 21b1d239125f1228e579b1ce8d94d4d5feadd2a6 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 21b1d239125f1228e579b1ce8d94d4d5feadd2a6
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/forms/models.py b/django/forms/models.py
--- a/django/forms/models.py
+++ b/django/forms/models.py
@@ -48,8 +48,11 @@ def construct_instance(form, instance, fields=None, exclude=None):
             continue
         # Leave defaults for fields that aren't in POST data, except for
         # checkbox inputs because they don't appear in POST data if not checked.
-        if (f.has_default() and
-                form[f.name].field.widget.value_omitted_from_data(form.data, form.files, form.add_prefix(f.name))):
+        if (
+            f.has_default() and
+            form[f.name].field.widget.value_omitted_from_data(form.data, form.files, form.add_prefix(f.name)) and
+            cleaned_data.get(f.name) in form[f.name].field.empty_values
+        ):
             continue
         # Defer saving file-type fields until after the other fields, so a
         # callable upload_to can use the values from other fields.

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11433.py
new file mode 100644
index e69de29..fa3fa30 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11433.py
@@ -0,0 +1,33 @@
+from django.test import TestCase
+from django.forms import ModelForm
+from django.db import models
+from django.forms.models import construct_instance
+
+# Step 1: Create a model with a field that has a default value
+class TestModel(models.Model):
+    name = models.CharField(max_length=100, default='default_name')
+
+    class Meta:
+        app_label = 'test_app'
+
+# Step 2: Create a form for this model, including the field with the default value
+class TestModelForm(ModelForm):
+    class Meta:
+        model = TestModel
+        fields = ['name']  # Include 'name' field
+
+    def clean(self):
+        # Step 3: Set up cleaned_data to include a value for the field
+        cleaned_data = super().clean()
+        cleaned_data['name'] = 'cleaned_name'
+        return cleaned_data
+
+class TestModelFormTest(TestCase):
+    def test_cleaned_data_overwrites_default(self):
+        # Step 4: Use construct_instance to apply cleaned_data to a model instance
+        form = TestModelForm(data={})
+        form.is_valid()  # Trigger the cleaning process
+        instance = construct_instance(form, TestModel())
+
+        # Step 5: Assert that the field's value is correctly set to the cleaned_data value
+        self.assertEqual(instance.name, 'cleaned_name')  # This should pass once the bug is fixed

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/forms/models\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11433
cat coverage.cover
git checkout 21b1d239125f1228e579b1ce8d94d4d5feadd2a6
git apply /root/pre_state.patch
