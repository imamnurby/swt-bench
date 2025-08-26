#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD e0442a628eb480eac6a7888aed5a86f83499e299 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff e0442a628eb480eac6a7888aed5a86f83499e299
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/contrib/admin/options.py b/django/contrib/admin/options.py
--- a/django/contrib/admin/options.py
+++ b/django/contrib/admin/options.py
@@ -269,7 +269,9 @@ def formfield_for_foreignkey(self, db_field, request, **kwargs):
                         "class": get_ul_class(self.radio_fields[db_field.name]),
                     }
                 )
-                kwargs["empty_label"] = _("None") if db_field.blank else None
+                kwargs["empty_label"] = (
+                    kwargs.get("empty_label", _("None")) if db_field.blank else None
+                )
 
         if "queryset" not in kwargs:
             queryset = self.get_field_queryset(db, db_field, request)

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15467.py
new file mode 100644
index e69de29..b4cf350 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15467.py
@@ -0,0 +1,33 @@
+from django.test import SimpleTestCase
+from django.contrib.admin import ModelAdmin
+from django.db import models
+from django.contrib import admin
+from django.contrib.contenttypes.models import ContentType
+from django.contrib.auth.models import Permission
+
+# Mock model to simulate the foreign key field
+class MockModel(models.Model):
+    myfield = models.ForeignKey('self', on_delete=models.CASCADE, blank=True, null=True)
+
+    class Meta:
+        app_label = 'myapp'
+
+# Mock ModelAdmin to override formfield_for_foreignkey
+class MockModelAdmin(ModelAdmin):
+    radio_fields = {'myfield': None}
+
+    def formfield_for_foreignkey(self, db_field, request, **kwargs):
+        if db_field.name == 'myfield':
+            kwargs['empty_label'] = "I WANT TO SET MY OWN EMPTY LABEL"
+        return super().formfield_for_foreignkey(db_field, request, **kwargs)
+
+class TestModelAdminEmptyLabel(SimpleTestCase):
+    def test_empty_label_override(self):
+        model_admin = MockModelAdmin(MockModel, admin.site)
+        mock_field = MockModel._meta.get_field('myfield')
+
+        # Simulate calling formfield_for_foreignkey
+        formfield = model_admin.formfield_for_foreignkey(mock_field, None)
+
+        # Check if the empty_label is overridden
+        self.assertEqual(formfield.empty_label, "I WANT TO SET MY OWN EMPTY LABEL")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/admin/options\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15467
cat coverage.cover
git checkout e0442a628eb480eac6a7888aed5a86f83499e299
git apply /root/pre_state.patch
