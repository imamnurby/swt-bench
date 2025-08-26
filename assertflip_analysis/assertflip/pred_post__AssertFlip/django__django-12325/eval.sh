#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 29c126bb349526b5f1cd78facbe9f25906f18563 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 29c126bb349526b5f1cd78facbe9f25906f18563
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/models/base.py b/django/db/models/base.py
--- a/django/db/models/base.py
+++ b/django/db/models/base.py
@@ -202,7 +202,7 @@ def __new__(cls, name, bases, attrs, **kwargs):
                 continue
             # Locate OneToOneField instances.
             for field in base._meta.local_fields:
-                if isinstance(field, OneToOneField):
+                if isinstance(field, OneToOneField) and field.remote_field.parent_link:
                     related = resolve_relation(new_class, field.remote_field.model)
                     parent_links[make_model_tuple(related)] = field
 
diff --git a/django/db/models/options.py b/django/db/models/options.py
--- a/django/db/models/options.py
+++ b/django/db/models/options.py
@@ -5,7 +5,7 @@
 
 from django.apps import apps
 from django.conf import settings
-from django.core.exceptions import FieldDoesNotExist, ImproperlyConfigured
+from django.core.exceptions import FieldDoesNotExist
 from django.db import connections
 from django.db.models import Manager
 from django.db.models.fields import AutoField
@@ -251,10 +251,6 @@ def _prepare(self, model):
                     field = already_created[0]
                 field.primary_key = True
                 self.setup_pk(field)
-                if not field.remote_field.parent_link:
-                    raise ImproperlyConfigured(
-                        'Add parent_link=True to %s.' % field,
-                    )
             else:
                 auto = AutoField(verbose_name='ID', primary_key=True, auto_created=True)
                 model.add_to_class('id', auto)

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-12325.py
new file mode 100644
index e69de29..f1ab7eb 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-12325.py
@@ -0,0 +1,33 @@
+from django.test import TestCase
+from django.db import models
+from django.core.exceptions import ImproperlyConfigured
+
+class Document(models.Model):
+    class Meta:
+        app_label = 'test_app'
+
+class PickingModelTest(TestCase):
+    databases = {'default'}
+
+    def test_mti_field_order_bug(self):
+        """
+        Test that the order of OneToOneField declarations in a model using MTI
+        does not raise an ImproperlyConfigured error when 'origin' is declared before 'document_ptr'.
+        """
+
+        # Define the Picking model with fields in the problematic order
+        class Picking(Document):
+            class Meta:
+                app_label = 'test_app'
+            origin = models.OneToOneField(Document, related_name='picking', on_delete=models.PROTECT)
+            document_ptr = models.OneToOneField(Document, on_delete=models.CASCADE, parent_link=True, related_name='+')
+
+        # Attempt to access the model's meta options to trigger configuration checks
+        try:
+            # Accessing the field should trigger the ImproperlyConfigured error
+            Picking._meta.get_field('origin')
+            # If the exception is raised, the test should pass, indicating the bug is fixed
+            assert False, "ImproperlyConfigured exception was not raised, indicating the bug is still present."
+        except ImproperlyConfigured:
+            # The test should pass if the ImproperlyConfigured exception is raised
+            assert True, "ImproperlyConfigured exception was raised as expected."

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/base\.py|django/db/models/options\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-12325
cat coverage.cover
git checkout 29c126bb349526b5f1cd78facbe9f25906f18563
git apply /root/pre_state.patch
