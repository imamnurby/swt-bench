#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD ece18207cbb64dd89014e279ac636a6c9829828e >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff ece18207cbb64dd89014e279ac636a6c9829828e
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/models/fields/files.py b/django/db/models/fields/files.py
--- a/django/db/models/fields/files.py
+++ b/django/db/models/fields/files.py
@@ -229,6 +229,8 @@ def __init__(self, verbose_name=None, name=None, upload_to='', storage=None, **k
 
         self.storage = storage or default_storage
         if callable(self.storage):
+            # Hold a reference to the callable for deconstruct().
+            self._storage_callable = self.storage
             self.storage = self.storage()
             if not isinstance(self.storage, Storage):
                 raise TypeError(
@@ -279,7 +281,7 @@ def deconstruct(self):
             del kwargs["max_length"]
         kwargs['upload_to'] = self.upload_to
         if self.storage is not default_storage:
-            kwargs['storage'] = self.storage
+            kwargs['storage'] = getattr(self, '_storage_callable', self.storage)
         return name, path, args, kwargs
 
     def get_internal_type(self):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13343.py
new file mode 100644
index e69de29..7041392 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13343.py
@@ -0,0 +1,22 @@
+from django.test import SimpleTestCase
+from django.core.files.storage import Storage
+from django.db.models import FileField
+
+class MockStorage(Storage):
+    pass
+
+def mock_storage_callable():
+    return MockStorage()
+
+class FileFieldDeconstructTests(SimpleTestCase):
+    def test_filefield_with_callable_storage_deconstructs_correctly(self):
+        """
+        Test that a FileField with a callable storage deconstructs correctly
+        by preserving the callable instead of evaluating it.
+        """
+        field = FileField(storage=mock_storage_callable)
+        name, path, args, kwargs = field.deconstruct()
+
+        # The storage should be the callable itself, not the evaluated result
+        self.assertIs(kwargs['storage'], mock_storage_callable)
+        self.assertNotIsInstance(kwargs['storage'], MockStorage)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/fields/files\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13343
cat coverage.cover
git checkout ece18207cbb64dd89014e279ac636a6c9829828e
git apply /root/pre_state.patch
