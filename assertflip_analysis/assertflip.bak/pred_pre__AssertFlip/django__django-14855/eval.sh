#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 475cffd1d64c690cdad16ede4d5e81985738ceb4 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 475cffd1d64c690cdad16ede4d5e81985738ceb4
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14855.py
new file mode 100644
index e69de29..6bdedd3 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14855.py
@@ -0,0 +1,66 @@
+from django.test import SimpleTestCase
+from django.contrib.admin.sites import AdminSite
+from django.contrib.admin import ModelAdmin
+from django.contrib.admin.helpers import AdminReadonlyField
+from django.urls import reverse, NoReverseMatch
+from django.utils.html import format_html
+from django.db import models
+from django import forms
+
+# Define the models within the test app
+class RelatedModel(models.Model):
+    name = models.CharField(max_length=100)
+
+    class Meta:
+        app_label = 'test_app'
+
+class MainModel(models.Model):
+    related = models.ForeignKey(RelatedModel, on_delete=models.CASCADE)
+
+    class Meta:
+        app_label = 'test_app'
+
+# ModelAdmin for MainModel
+class MainModelAdmin(ModelAdmin):
+    readonly_fields = ['related']
+
+# Custom Admin Site
+class CustomAdminSite(AdminSite):
+    site_header = 'Custom Admin'
+    name = 'custom-admin'
+
+# Dummy form to pass to AdminReadonlyField
+class DummyForm(forms.ModelForm):
+    class Meta:
+        model = MainModel
+        fields = '__all__'
+
+# Test case
+class AdminURLTest(SimpleTestCase):
+    def setUp(self):
+        self.site = CustomAdminSite()
+        self.site.register(MainModel, MainModelAdmin)
+        self.related_instance = RelatedModel(name='Related')
+        self.main_instance = MainModel(related=self.related_instance)
+        self.model_admin = self.site._registry[MainModel]
+        self.form = DummyForm(instance=self.main_instance)
+
+    def test_get_admin_url_for_readonly_foreignkey(self):
+        # Create an AdminReadonlyField instance
+        field = AdminReadonlyField(
+            form=self.form,
+            field='related',
+            is_first=False,
+            model_admin=self.model_admin
+        )
+        
+        # Simulate the get_admin_url method
+        url_name = 'admin:%s_%s_change' % (RelatedModel._meta.app_label, RelatedModel._meta.model_name)
+        try:
+            url = reverse(url_name, args=[self.related_instance.pk], current_app=self.model_admin.admin_site.name)
+            url = format_html('<a href="{}">{}</a>', url, self.related_instance)
+        except NoReverseMatch:
+            url = '/admin/'  # Simulate the incorrect behavior
+        
+        # Assert the URL starts with '/custom-admin/' which is the correct behavior
+        self.assertTrue(url.startswith('/custom-admin/'))

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/admin/helpers\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14855
cat coverage.cover
git checkout 475cffd1d64c690cdad16ede4d5e81985738ceb4
git apply /root/pre_state.patch
