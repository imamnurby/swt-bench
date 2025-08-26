#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 88e67a54b7ed0210c11523a337b498aadb2f5187 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 88e67a54b7ed0210c11523a337b498aadb2f5187
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15916.py
new file mode 100644
index e69de29..1823049 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15916.py
@@ -0,0 +1,36 @@
+from django.test import SimpleTestCase
+from django import forms
+from django.db import models
+from django.forms import modelform_factory
+
+class TestModel(models.Model):
+    active = models.BooleanField()
+    name = models.CharField(max_length=64, blank=True, null=True)
+
+    class Meta:
+        app_label = 'test_app'
+
+def all_required(field, **kwargs):
+    formfield = field.formfield(**kwargs)
+    formfield.required = True
+    return formfield
+
+class MyForm(forms.ModelForm):
+    class Meta:
+        model = TestModel
+        formfield_callback = all_required
+        fields = ['active', 'name']
+
+class ModelFormFactoryTest(SimpleTestCase):
+    def test_modelform_factory_uses_meta_formfield_callback(self):
+        """
+        Test that modelform_factory uses the formfield_callback specified
+        in the Meta class of the provided form class. The fields should be
+        required, which is the correct behavior once the bug is fixed.
+        """
+        FactoryForm = modelform_factory(TestModel, form=MyForm)
+        form = FactoryForm()
+
+        # Check if the fields are required, which is the correct behavior
+        self.assertTrue(form.fields['active'].required)
+        self.assertTrue(form.fields['name'].required)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/forms/models\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15916
cat coverage.cover
git checkout 88e67a54b7ed0210c11523a337b498aadb2f5187
git apply /root/pre_state.patch
