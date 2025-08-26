#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 8c3bd0b708b488a1f6e8bd8cc6b96569904605be >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 8c3bd0b708b488a1f6e8bd8cc6b96569904605be
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/migrations/executor.py b/django/db/migrations/executor.py
--- a/django/db/migrations/executor.py
+++ b/django/db/migrations/executor.py
@@ -250,12 +250,11 @@ def unapply_migration(self, state, migration, fake=False):
         if not fake:
             with self.connection.schema_editor(atomic=migration.atomic) as schema_editor:
                 state = migration.unapply(state, schema_editor)
-        # For replacement migrations, record individual statuses
+        # For replacement migrations, also record individual statuses.
         if migration.replaces:
             for app_label, name in migration.replaces:
                 self.recorder.record_unapplied(app_label, name)
-        else:
-            self.recorder.record_unapplied(migration.app_label, migration.name)
+        self.recorder.record_unapplied(migration.app_label, migration.name)
         # Report progress
         if self.progress_callback:
             self.progress_callback("unapply_success", migration, fake)

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14500.py
new file mode 100644
index e69de29..e0726a5 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14500.py
@@ -0,0 +1,37 @@
+from django.test import TestCase
+from django.db import connection
+from django.db.migrations.executor import MigrationExecutor
+from django.db.migrations.recorder import MigrationRecorder
+from unittest.mock import MagicMock
+
+class SquashedMigrationUnapplyTest(TestCase):
+    def setUp(self):
+        # Set up the mock migration environment
+        self.executor = MigrationExecutor(connection)
+        self.recorder = MigrationRecorder(connection)
+        
+        # Mock squashed migration and its replaced migrations
+        self.squashed_migration = MagicMock()
+        self.squashed_migration.app_label = 'app'
+        self.squashed_migration.name = '0002_squashed'
+        self.squashed_migration.replaces = [('app', '0001_initial'), ('app', '0002_auto')]
+        
+        # Mark replaced migrations as applied
+        for app_label, name in self.squashed_migration.replaces:
+            self.recorder.record_applied(app_label, name)
+        
+        # Ensure squashed migration is initially marked as applied
+        self.recorder.record_applied(self.squashed_migration.app_label, self.squashed_migration.name)
+
+    def test_unapply_squashed_migration_with_replaced_present(self):
+        # Unapply the squashed migration with fake=True to avoid schema editor issues
+        self.executor.unapply_migration(None, self.squashed_migration, fake=True)
+        
+        # Check if the squashed migration is marked as unapplied
+        unapplied_migrations = self.recorder.applied_migrations()
+        
+        # Assert that the squashed migration is correctly not marked as unapplied
+        self.assertNotIn((self.squashed_migration.app_label, self.squashed_migration.name), unapplied_migrations)
+        
+        # Cleanup: Ensure no state pollution
+        self.recorder.flush()

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/migrations/executor\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14500
cat coverage.cover
git checkout 8c3bd0b708b488a1f6e8bd8cc6b96569904605be
git apply /root/pre_state.patch
