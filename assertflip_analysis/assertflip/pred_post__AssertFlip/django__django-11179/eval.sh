#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 19fc6376ce67d01ca37a91ef2f55ef769f50513a >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 19fc6376ce67d01ca37a91ef2f55ef769f50513a
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/models/deletion.py b/django/db/models/deletion.py
--- a/django/db/models/deletion.py
+++ b/django/db/models/deletion.py
@@ -277,6 +277,7 @@ def delete(self):
             if self.can_fast_delete(instance):
                 with transaction.mark_for_rollback_on_error():
                     count = sql.DeleteQuery(model).delete_batch([instance.pk], self.using)
+                setattr(instance, model._meta.pk.attname, None)
                 return count, {model._meta.label: count}
 
         with transaction.atomic(using=self.using, savepoint=False):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11179.py
new file mode 100644
index e69de29..5f868d9 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11179.py
@@ -0,0 +1,27 @@
+from django.test import TestCase
+from django.db import models, connection
+
+# Define a simple model for testing
+class SimpleModel(models.Model):
+    name = models.CharField(max_length=100)
+
+    class Meta:
+        app_label = 'test_app'
+
+class DeleteModelTestCase(TestCase):
+    def setUp(self):
+        # Create the table for SimpleModel
+        with connection.cursor() as cursor:
+            cursor.execute('CREATE TABLE IF NOT EXISTS test_app_simplemodel (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(100));')
+        # Create and save a model instance
+        self.instance = SimpleModel.objects.create(name="Test Name")
+
+    def test_delete_model_pk_not_none_after_delete(self):
+        # Ensure the instance has a primary key before deletion
+        self.assertIsNotNone(self.instance.pk)
+
+        # Delete the instance
+        self.instance.delete()
+
+        # Check that the primary key is None after deletion
+        self.assertIsNone(self.instance.pk)  # The PK should be None after deletion

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/deletion\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11179
cat coverage.cover
git checkout 19fc6376ce67d01ca37a91ef2f55ef769f50513a
git apply /root/pre_state.patch
