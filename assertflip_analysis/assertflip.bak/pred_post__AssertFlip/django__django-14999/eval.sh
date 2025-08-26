#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a754b82dac511475b6276039471ccd17cc64aeb8 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a754b82dac511475b6276039471ccd17cc64aeb8
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/migrations/operations/models.py b/django/db/migrations/operations/models.py
--- a/django/db/migrations/operations/models.py
+++ b/django/db/migrations/operations/models.py
@@ -320,12 +320,13 @@ def database_forwards(self, app_label, schema_editor, from_state, to_state):
         new_model = to_state.apps.get_model(app_label, self.new_name)
         if self.allow_migrate_model(schema_editor.connection.alias, new_model):
             old_model = from_state.apps.get_model(app_label, self.old_name)
+            old_db_table = old_model._meta.db_table
+            new_db_table = new_model._meta.db_table
+            # Don't alter when a table name is not changed.
+            if old_db_table == new_db_table:
+                return
             # Move the main table
-            schema_editor.alter_db_table(
-                new_model,
-                old_model._meta.db_table,
-                new_model._meta.db_table,
-            )
+            schema_editor.alter_db_table(new_model, old_db_table, new_db_table)
             # Alter the fields pointing to us
             for related_object in old_model._meta.related_objects:
                 if related_object.related_model == old_model:

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14999.py
new file mode 100644
index e69de29..96dac57 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14999.py
@@ -0,0 +1,45 @@
+from django.test import TestCase
+from django.db import connection, models
+from django.db.migrations.state import ProjectState
+from django.db.migrations.operations.models import RenameModel
+from django.db.migrations.state import ModelState
+
+class RenameModelNoopTests(TestCase):
+    databases = {'default'}
+
+    def setUp(self):
+        self.app_label = 'testapp'
+        self.old_name = 'OldModel'
+        self.new_name = 'NewModel'
+        self.db_table = 'custom_table_name'
+        self.state = ProjectState()
+        self.state.add_model(ModelState(
+            self.app_label,
+            self.old_name,
+            [
+                ('id', models.AutoField(primary_key=True)),
+                ('name', models.CharField(max_length=255)),
+            ],
+            options={'db_table': self.db_table},
+        ))
+
+    def test_rename_model_with_db_table_noop(self):
+        # Apply the RenameModel operation
+        migration = RenameModel(self.old_name, self.new_name)
+        with connection.cursor() as cursor:
+            # Disable foreign key checks for SQLite
+            cursor.execute('PRAGMA foreign_keys = OFF;')
+
+            # Simulate the database forwards operation
+            from_state = self.state.clone()
+            to_state = from_state.clone()
+            migration.state_forwards(self.app_label, to_state)
+            migration.database_forwards(self.app_label, connection.schema_editor(), from_state, to_state)
+
+            # Check if the table was not recreated (correct behavior)
+            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=%s", [self.db_table])
+            result = cursor.fetchone()
+            self.assertIsNotNone(result)  # The table should exist, indicating no recreation
+
+            # Re-enable foreign key checks
+            cursor.execute('PRAGMA foreign_keys = ON;')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/migrations/operations/models\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14999
cat coverage.cover
git checkout a754b82dac511475b6276039471ccd17cc64aeb8
git apply /root/pre_state.patch
