#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 5b884d45ac5b76234eca614d90c83b347294c332 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 5b884d45ac5b76234eca614d90c83b347294c332
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/contrib/admin/options.py b/django/contrib/admin/options.py
--- a/django/contrib/admin/options.py
+++ b/django/contrib/admin/options.py
@@ -249,17 +249,25 @@ def formfield_for_manytomany(self, db_field, request, **kwargs):
             return None
         db = kwargs.get('using')
 
-        autocomplete_fields = self.get_autocomplete_fields(request)
-        if db_field.name in autocomplete_fields:
-            kwargs['widget'] = AutocompleteSelectMultiple(db_field.remote_field, self.admin_site, using=db)
-        elif db_field.name in self.raw_id_fields:
-            kwargs['widget'] = widgets.ManyToManyRawIdWidget(db_field.remote_field, self.admin_site, using=db)
-        elif db_field.name in [*self.filter_vertical, *self.filter_horizontal]:
-            kwargs['widget'] = widgets.FilteredSelectMultiple(
-                db_field.verbose_name,
-                db_field.name in self.filter_vertical
-            )
-
+        if 'widget' not in kwargs:
+            autocomplete_fields = self.get_autocomplete_fields(request)
+            if db_field.name in autocomplete_fields:
+                kwargs['widget'] = AutocompleteSelectMultiple(
+                    db_field.remote_field,
+                    self.admin_site,
+                    using=db,
+                )
+            elif db_field.name in self.raw_id_fields:
+                kwargs['widget'] = widgets.ManyToManyRawIdWidget(
+                    db_field.remote_field,
+                    self.admin_site,
+                    using=db,
+                )
+            elif db_field.name in [*self.filter_vertical, *self.filter_horizontal]:
+                kwargs['widget'] = widgets.FilteredSelectMultiple(
+                    db_field.verbose_name,
+                    db_field.name in self.filter_vertical
+                )
         if 'queryset' not in kwargs:
             queryset = self.get_field_queryset(db, db_field, request)
             if queryset is not None:

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-12713.py
new file mode 100644
index e69de29..fc9747d 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-12713.py
@@ -0,0 +1,38 @@
+from django.test import SimpleTestCase
+from django import forms
+from django.contrib.admin import ModelAdmin, AdminSite
+from django.db import models
+
+class CustomWidget(forms.Widget):
+    pass
+
+class TestModel(models.Model):
+    name = models.CharField(max_length=100)
+    related = models.ManyToManyField('self')
+
+    class Meta:
+        app_label = 'test_app'
+
+class TestModelAdmin(ModelAdmin):
+    def formfield_for_manytomany(self, db_field, request, **kwargs):
+        return super().formfield_for_manytomany(db_field, request, **kwargs)
+
+class MockAdminSite(AdminSite):
+    _registry = {}
+
+class FormFieldForManyToManyTests(SimpleTestCase):
+    def test_custom_widget_used(self):
+        """
+        Test that formfield_for_manytomany uses a custom widget
+        when one is provided in kwargs, ensuring the bug is fixed.
+        """
+        admin_site = MockAdminSite()
+        model_admin = TestModelAdmin(TestModel, admin_site)
+        custom_widget = CustomWidget()
+        form_field = model_admin.formfield_for_manytomany(
+            TestModel._meta.get_field('related'),
+            None,
+            widget=custom_widget
+        )
+        # The test should pass if the custom widget is used, ensuring the bug is fixed
+        self.assertEqual(form_field.widget, custom_widget)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/admin/options\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-12713
cat coverage.cover
git checkout 5b884d45ac5b76234eca614d90c83b347294c332
git apply /root/pre_state.patch
