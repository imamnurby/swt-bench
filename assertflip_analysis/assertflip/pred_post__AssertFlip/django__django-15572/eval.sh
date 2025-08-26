#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 0b31e024873681e187b574fe1c4afe5e48aeeecf >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 0b31e024873681e187b574fe1c4afe5e48aeeecf
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/template/autoreload.py b/django/template/autoreload.py
--- a/django/template/autoreload.py
+++ b/django/template/autoreload.py
@@ -17,7 +17,7 @@ def get_template_directories():
         if not isinstance(backend, DjangoTemplates):
             continue
 
-        items.update(cwd / to_path(dir) for dir in backend.engine.dirs)
+        items.update(cwd / to_path(dir) for dir in backend.engine.dirs if dir)
 
         for loader in backend.engine.template_loaders:
             if not hasattr(loader, "get_dirs"):
@@ -25,7 +25,7 @@ def get_template_directories():
             items.update(
                 cwd / to_path(directory)
                 for directory in loader.get_dirs()
-                if not is_django_path(directory)
+                if directory and not is_django_path(directory)
             )
     return items
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15572.py
new file mode 100644
index e69de29..9d2d820 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15572.py
@@ -0,0 +1,41 @@
+from django.test import SimpleTestCase, override_settings
+from django.utils.autoreload import autoreload_started, file_changed
+from django.dispatch import receiver
+from pathlib import Path
+import os
+
+class TemplateAutoreloadTests(SimpleTestCase):
+
+    @override_settings(TEMPLATES=[{
+        'BACKEND': 'django.template.backends.django.DjangoTemplates',
+        'DIRS': [''],  # Set DIRS to contain an empty string
+    }])
+    def test_autoreload_with_empty_template_dir(self):
+        """
+        Test that autoreload does not trigger when TEMPLATES DIRS contains an empty string.
+        """
+
+        # Simulate the environment variable TEMPLATES_DIRS to return an empty string
+        os.environ['TEMPLATES_DIRS'] = ''
+
+        # Start the autoreload mechanism
+        autoreload_triggered = []
+
+        @receiver(autoreload_started)
+        def on_autoreload_started(sender, **kwargs):
+            autoreload_triggered.append(True)
+
+        # Simulate a file change event
+        @receiver(file_changed)
+        def on_file_changed(sender, file_path, **kwargs):
+            # Convert file_path to a Path object to avoid AttributeError
+            file_path = Path(file_path)
+            # Simulate a non-Python file change
+            if file_path.suffix != '.py':
+                autoreload_triggered.append(True)
+
+        # Trigger a file change event
+        file_changed.send(sender=self.__class__, file_path=Path('template.html'))
+
+        # Assert that the autoreload mechanism does not trigger
+        self.assertFalse(autoreload_triggered, "Autoreload should not trigger due to the empty string in TEMPLATES DIRS.")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/template/autoreload\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15572
cat coverage.cover
git checkout 0b31e024873681e187b574fe1c4afe5e48aeeecf
git apply /root/pre_state.patch
