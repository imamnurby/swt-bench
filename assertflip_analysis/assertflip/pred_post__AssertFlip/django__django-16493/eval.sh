#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD e3a4cee081cf60650b8824f0646383b79cb110e7 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff e3a4cee081cf60650b8824f0646383b79cb110e7
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/models/fields/files.py b/django/db/models/fields/files.py
--- a/django/db/models/fields/files.py
+++ b/django/db/models/fields/files.py
@@ -295,8 +295,9 @@ def deconstruct(self):
         if kwargs.get("max_length") == 100:
             del kwargs["max_length"]
         kwargs["upload_to"] = self.upload_to
-        if self.storage is not default_storage:
-            kwargs["storage"] = getattr(self, "_storage_callable", self.storage)
+        storage = getattr(self, "_storage_callable", self.storage)
+        if storage is not default_storage:
+            kwargs["storage"] = storage
         return name, path, args, kwargs
 
     def get_internal_type(self):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16493.py
new file mode 100644
index e69de29..df7d34f 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16493.py
@@ -0,0 +1,26 @@
+from django.test import SimpleTestCase
+from django.test.utils import isolate_apps
+from django.core.files.storage import default_storage
+from django.db import models
+
+# Define a callable that always returns default_storage
+def get_default_storage():
+    return default_storage
+
+@isolate_apps("django.contrib.contenttypes")  # Use a built-in app to avoid ModuleNotFoundError
+class FileFieldDeconstructTest(SimpleTestCase):
+    def test_storage_callable_deconstruction(self):
+        """
+        Test that the storage argument is included when the callable returns default_storage.
+        """
+        class MyModel(models.Model):
+            my_file = models.FileField(storage=get_default_storage)
+
+            class Meta:
+                app_label = 'django.contrib.contenttypes'  # Use a valid app_label
+
+        name, path, args, kwargs = MyModel._meta.get_field('my_file').deconstruct()
+
+        # Check that the storage argument is included when the callable returns default_storage
+        self.assertIn("storage", kwargs)
+        self.assertEqual(kwargs["storage"], "path.to.get_default_storage")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/fields/files\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16493
cat coverage.cover
git checkout e3a4cee081cf60650b8824f0646383b79cb110e7
git apply /root/pre_state.patch
