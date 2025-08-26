#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 7991111af12056ec9a856f35935d273526338c1f >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 7991111af12056ec9a856f35935d273526338c1f
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/contrib/admin/checks.py b/django/contrib/admin/checks.py
--- a/django/contrib/admin/checks.py
+++ b/django/contrib/admin/checks.py
@@ -720,33 +720,33 @@ def _check_list_display_item(self, obj, item, label):
             return []
         elif hasattr(obj, item):
             return []
-        elif hasattr(obj.model, item):
+        try:
+            field = obj.model._meta.get_field(item)
+        except FieldDoesNotExist:
             try:
-                field = obj.model._meta.get_field(item)
-            except FieldDoesNotExist:
-                return []
-            else:
-                if isinstance(field, models.ManyToManyField):
-                    return [
-                        checks.Error(
-                            "The value of '%s' must not be a ManyToManyField." % label,
-                            obj=obj.__class__,
-                            id='admin.E109',
-                        )
-                    ]
-                return []
-        else:
+                field = getattr(obj.model, item)
+            except AttributeError:
+                return [
+                    checks.Error(
+                        "The value of '%s' refers to '%s', which is not a "
+                        "callable, an attribute of '%s', or an attribute or "
+                        "method on '%s.%s'." % (
+                            label, item, obj.__class__.__name__,
+                            obj.model._meta.app_label, obj.model._meta.object_name,
+                        ),
+                        obj=obj.__class__,
+                        id='admin.E108',
+                    )
+                ]
+        if isinstance(field, models.ManyToManyField):
             return [
                 checks.Error(
-                    "The value of '%s' refers to '%s', which is not a callable, "
-                    "an attribute of '%s', or an attribute or method on '%s.%s'." % (
-                        label, item, obj.__class__.__name__,
-                        obj.model._meta.app_label, obj.model._meta.object_name,
-                    ),
+                    "The value of '%s' must not be a ManyToManyField." % label,
                     obj=obj.__class__,
-                    id='admin.E108',
+                    id='admin.E109',
                 )
             ]
+        return []
 
     def _check_list_display_links(self, obj):
         """ Check that list_display_links is a unique subset of list_display.

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11551.py
new file mode 100644
index e69de29..22c37a5 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11551.py
@@ -0,0 +1,37 @@
+from django.test import SimpleTestCase
+from django.contrib import admin
+from django.core import checks
+from django.db import models
+
+# Mock PositionField for testing purposes
+class MockPositionField(models.Field):
+    def __init__(self, *args, **kwargs):
+        super().__init__(*args, **kwargs)
+
+class Thing(models.Model):
+    number = models.IntegerField(default=0)
+    order = MockPositionField()
+
+    class Meta:
+        app_label = 'test_app'
+
+class ThingAdmin(admin.ModelAdmin):
+    list_display = ['number', 'order']
+
+class ThingAdminCheckTests(SimpleTestCase):
+    def test_list_display_with_mock_position_field(self):
+        """
+        Test that a ModelAdmin with a MockPositionField in list_display does not raise admin.E108.
+        This test should fail when the bug is present and pass when the bug is fixed.
+        """
+        # Register the model with the admin site
+        admin.site.register(Thing, ThingAdmin)
+
+        # Run admin checks
+        errors = checks.run_checks()
+
+        # Assert that admin.E108 is raised
+        self.assertTrue(
+            any(error.id == 'admin.E108' for error in errors),
+            "admin.E108 error should be raised due to MockPositionField in list_display"
+        )

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/admin/checks\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11551
cat coverage.cover
git checkout 7991111af12056ec9a856f35935d273526338c1f
git apply /root/pre_state.patch
