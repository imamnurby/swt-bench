#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 7d49ad76562e8c0597a0eb66046ab423b12888d8 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 7d49ad76562e8c0597a0eb66046ab423b12888d8
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/contrib/admin/options.py b/django/contrib/admin/options.py
--- a/django/contrib/admin/options.py
+++ b/django/contrib/admin/options.py
@@ -327,6 +327,10 @@ def get_fieldsets(self, request, obj=None):
             return self.fieldsets
         return [(None, {'fields': self.get_fields(request, obj)})]
 
+    def get_inlines(self, request, obj):
+        """Hook for specifying custom inlines."""
+        return self.inlines
+
     def get_ordering(self, request):
         """
         Hook for specifying field ordering.
@@ -582,7 +586,7 @@ def __str__(self):
 
     def get_inline_instances(self, request, obj=None):
         inline_instances = []
-        for inline_class in self.inlines:
+        for inline_class in self.get_inlines(request, obj):
             inline = inline_class(self.model, self.admin_site)
             if request:
                 if not (inline.has_view_or_change_permission(request, obj) or

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11095.py
new file mode 100644
index e69de29..e5337ef 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11095.py
@@ -0,0 +1,44 @@
+from django.test import SimpleTestCase, RequestFactory
+from django.contrib.admin import ModelAdmin
+from django.contrib.auth.models import User
+from django.contrib import admin
+from django.db import models
+
+# Mock model to use with ModelAdmin
+class MockModel(models.Model):
+    name = models.CharField(max_length=100)
+
+    class Meta:
+        app_label = 'test_app'
+
+# Mock inline class
+class MockInline(admin.TabularInline):
+    model = MockModel
+
+    def has_view_or_change_permission(self, request, obj=None):
+        return True
+
+    def has_add_permission(self, request, obj=None):
+        return True
+
+    def has_delete_permission(self, request, obj=None):
+        return True
+
+# Mock ModelAdmin without a custom get_inlines method
+class MockModelAdmin(ModelAdmin):
+    inlines = [MockInline]
+
+class TestModelAdmin(SimpleTestCase):
+    def setUp(self):
+        self.factory = RequestFactory()
+        self.request = self.factory.get('/admin/')
+        self.admin_site = admin.sites.AdminSite()
+        self.model = MockModel
+
+    def test_get_inline_instances_without_get_inlines(self):
+        admin_instance = MockModelAdmin(self.model, self.admin_site)
+        inline_instances = admin_instance.get_inline_instances(self.request)
+
+        # Assert that the inlines returned by get_inline_instances are dynamically set
+        # This test should fail until the get_inlines method is implemented
+        self.assertNotEqual(len(inline_instances), 1)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/admin/options\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11095
cat coverage.cover
git checkout 7d49ad76562e8c0597a0eb66046ab423b12888d8
git apply /root/pre_state.patch
