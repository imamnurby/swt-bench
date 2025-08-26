#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 3b62d8c83e3e48d2ed61cfa32a61c56d9e030293 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 3b62d8c83e3e48d2ed61cfa32a61c56d9e030293
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/models/fields/files.py b/django/db/models/fields/files.py
--- a/django/db/models/fields/files.py
+++ b/django/db/models/fields/files.py
@@ -441,7 +441,8 @@ def contribute_to_class(self, cls, name, **kwargs):
         # after their corresponding image field don't stay cleared by
         # Model.__init__, see bug #11196.
         # Only run post-initialization dimension update on non-abstract models
-        if not cls._meta.abstract:
+        # with width_field/height_field.
+        if not cls._meta.abstract and (self.width_field or self.height_field):
             signals.post_init.connect(self.update_dimension_fields, sender=cls)
 
     def update_dimension_fields(self, instance, force=False, *args, **kwargs):
@@ -457,10 +458,8 @@ def update_dimension_fields(self, instance, force=False, *args, **kwargs):
         Dimensions can be forced to update with force=True, which is how
         ImageFileDescriptor.__set__ calls this method.
         """
-        # Nothing to update if the field doesn't have dimension fields or if
-        # the field is deferred.
-        has_dimension_fields = self.width_field or self.height_field
-        if not has_dimension_fields or self.attname not in instance.__dict__:
+        # Nothing to update if the field is deferred.
+        if self.attname not in instance.__dict__:
             return
 
         # getattr will call the ImageFileDescriptor's __get__ method, which

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16801.py
new file mode 100644
index e69de29..5981a07 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16801.py
@@ -0,0 +1,27 @@
+from django.test import SimpleTestCase
+from django.db import models
+from django.db.models.signals import post_init
+
+class ImageFieldPostInitSignalTest(SimpleTestCase):
+    def setUp(self):
+        # Dynamically create a model within a test app
+        class TestModel(models.Model):
+            image = models.ImageField()
+
+            class Meta:
+                app_label = 'test_app'
+
+        self.TestModel = TestModel
+
+    def test_post_init_signal_unnecessary_connection(self):
+        """
+        Test to check if the post_init signal is connected even when width_field and height_field are not set.
+        This test should fail if the post_init signal is unnecessarily connected.
+        """
+        # Check if the post_init signal is connected to the TestModel
+        connected_receivers = post_init.receivers
+        image_field_connected = any(
+            receiver[1]() == self.TestModel._meta.get_field('image').update_dimension_fields for receiver in connected_receivers
+        )
+        # Assert that the post_init signal is not connected, which is the correct behavior
+        self.assertFalse(image_field_connected, "BUG: post_init signal should not be connected when width_field and height_field are not set.")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/fields/files\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16801
cat coverage.cover
git checkout 3b62d8c83e3e48d2ed61cfa32a61c56d9e030293
git apply /root/pre_state.patch
