#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d3d173425fc0a1107836da5b4567f1c88253191b >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d3d173425fc0a1107836da5b4567f1c88253191b
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/contrib/admin/checks.py b/django/contrib/admin/checks.py
--- a/django/contrib/admin/checks.py
+++ b/django/contrib/admin/checks.py
@@ -771,10 +771,11 @@ def _check_readonly_fields_item(self, obj, field_name, label):
             except FieldDoesNotExist:
                 return [
                     checks.Error(
-                        "The value of '%s' is not a callable, an attribute of "
-                        "'%s', or an attribute of '%s'."
+                        "The value of '%s' refers to '%s', which is not a callable, "
+                        "an attribute of '%s', or an attribute of '%s'."
                         % (
                             label,
+                            field_name,
                             obj.__class__.__name__,
                             obj.model._meta.label,
                         ),

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16899.py
new file mode 100644
index e69de29..0d2af7f 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16899.py
@@ -0,0 +1,37 @@
+from django.test import SimpleTestCase
+from django.contrib.admin import ModelAdmin, AdminSite
+from django.core import checks
+from django.db import models
+
+class MockModel(models.Model):
+    name = models.CharField(max_length=100)
+
+    class Meta:
+        app_label = 'test_app'
+
+class MockAdminSite(AdminSite):
+    pass
+
+class MockModelAdmin(ModelAdmin):
+    model = MockModel
+    readonly_fields = ['non_existent_field']
+
+class ReadonlyFieldsErrorMessageTest(SimpleTestCase):
+    def test_readonly_fields_error_message(self):
+        """
+        Test that the error message for readonly_fields includes the field name.
+        This test fails because the current behavior is incorrect and does not include the field name.
+        """
+        admin_site = MockAdminSite()
+        admin_obj = MockModelAdmin(MockModel, admin_site)
+        errors = admin_obj.check()
+
+        # Find the specific error related to readonly_fields
+        readonly_fields_error = next(
+            (error for error in errors if error.id == 'admin.E035'), None
+        )
+
+        self.assertIsNotNone(readonly_fields_error, "Expected an error related to readonly_fields.")
+        self.assertIn("readonly_fields[0]", readonly_fields_error.msg)
+        # Correct behavior: the field name should be included in the error message
+        self.assertIn("non_existent_field", readonly_fields_error.msg)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/admin/checks\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16899
cat coverage.cover
git checkout d3d173425fc0a1107836da5b4567f1c88253191b
git apply /root/pre_state.patch
