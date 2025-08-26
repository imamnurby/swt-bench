#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 537d422942b53bc0a2b6a51968f379c0de07793c >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 537d422942b53bc0a2b6a51968f379c0de07793c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/core/management/commands/flush.py b/django/core/management/commands/flush.py
--- a/django/core/management/commands/flush.py
+++ b/django/core/management/commands/flush.py
@@ -60,7 +60,7 @@ def handle(self, **options):
 
         if confirm == 'yes':
             try:
-                connection.ops.execute_sql_flush(database, sql_list)
+                connection.ops.execute_sql_flush(sql_list)
             except Exception as exc:
                 raise CommandError(
                     "Database %s couldn't be flushed. Possible reasons:\n"
diff --git a/django/db/backends/base/operations.py b/django/db/backends/base/operations.py
--- a/django/db/backends/base/operations.py
+++ b/django/db/backends/base/operations.py
@@ -400,9 +400,12 @@ def sql_flush(self, style, tables, *, reset_sequences=False, allow_cascade=False
         """
         raise NotImplementedError('subclasses of BaseDatabaseOperations must provide a sql_flush() method')
 
-    def execute_sql_flush(self, using, sql_list):
+    def execute_sql_flush(self, sql_list):
         """Execute a list of SQL statements to flush the database."""
-        with transaction.atomic(using=using, savepoint=self.connection.features.can_rollback_ddl):
+        with transaction.atomic(
+            using=self.connection.alias,
+            savepoint=self.connection.features.can_rollback_ddl,
+        ):
             with self.connection.cursor() as cursor:
                 for sql in sql_list:
                     cursor.execute(sql)

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-12741.py
new file mode 100644
index e69de29..403146e 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-12741.py
@@ -0,0 +1,47 @@
+from django.test import TestCase
+from unittest.mock import MagicMock, patch
+from django.db import transaction
+
+class ExecuteSQLFlushTests(TestCase):
+    def setUp(self):
+        # Mock the connection and cursor
+        self.connection = MagicMock()
+        self.connection.alias = 'default'
+        self.connection.features.can_rollback_ddl = True
+        self.cursor = MagicMock()
+        self.connection.cursor.return_value.__enter__.return_value = self.cursor
+
+        # Mock the operations object
+        self.ops = MagicMock()
+        self.ops.connection = self.connection
+
+    @patch('django.db.transaction.atomic')
+    def test_execute_sql_flush_with_using_argument(self, mock_atomic):
+        # Sample SQL list
+        sql_list = ['DELETE FROM my_table;']
+
+        # Mock the transaction.atomic context manager
+        mock_atomic.return_value.__enter__.return_value = None
+
+        # Call the method with the 'using' argument
+        self.ops.execute_sql_flush('default', sql_list)
+
+        # Assert that the SQL statements are executed
+        self.assertTrue(self.cursor.execute.called)  # This should be True if the method worked correctly
+
+    @patch('django.db.transaction.atomic')
+    def test_execute_sql_flush_without_using_argument(self, mock_atomic):
+        # Sample SQL list
+        sql_list = ['DELETE FROM my_table;']
+
+        # Mock the transaction.atomic context manager
+        mock_atomic.return_value.__enter__.return_value = None
+
+        # Call the method without the 'using' argument
+        try:
+            self.ops.execute_sql_flush(sql_list)
+        except TypeError as e:
+            self.fail("Expected the method to work without 'using' argument, but it raised an error: " + str(e))
+
+        # Ensure that the cursor's execute method was called, indicating the SQL was attempted to be executed
+        self.assertTrue(self.cursor.execute.called)  # This should be True if the method worked correctly

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/backends/base/operations\.py|django/core/management/commands/flush\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-12741
cat coverage.cover
git checkout 537d422942b53bc0a2b6a51968f379c0de07793c
git apply /root/pre_state.patch
