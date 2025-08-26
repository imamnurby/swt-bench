#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD dab48b7482295956973879d15bfd4d3bb0718772 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff dab48b7482295956973879d15bfd4d3bb0718772
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/core/management/commands/inspectdb.py b/django/core/management/commands/inspectdb.py
--- a/django/core/management/commands/inspectdb.py
+++ b/django/core/management/commands/inspectdb.py
@@ -116,13 +116,17 @@ def table2model(table_name):
                         extra_params['unique'] = True
 
                     if is_relation:
+                        ref_db_column, ref_db_table = relations[column_name]
                         if extra_params.pop('unique', False) or extra_params.get('primary_key'):
                             rel_type = 'OneToOneField'
                         else:
                             rel_type = 'ForeignKey'
+                            ref_pk_column = connection.introspection.get_primary_key_column(cursor, ref_db_table)
+                            if ref_pk_column and ref_pk_column != ref_db_column:
+                                extra_params['to_field'] = ref_db_column
                         rel_to = (
-                            "self" if relations[column_name][1] == table_name
-                            else table2model(relations[column_name][1])
+                            'self' if ref_db_table == table_name
+                            else table2model(ref_db_table)
                         )
                         if rel_to in known_models:
                             field_type = '%s(%s' % (rel_type, rel_to)

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15037.py
new file mode 100644
index e69de29..7d11ca0 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15037.py
@@ -0,0 +1,34 @@
+from django.test import TestCase
+from django.db import connection
+from django.core.management import call_command
+from io import StringIO
+
+class InspectDBForeignKeyTest(TestCase):
+    def setUp(self):
+        with connection.cursor() as cursor:
+            cursor.execute("""
+                CREATE TABLE foo (
+                    id serial PRIMARY KEY,
+                    other_id int UNIQUE
+                );
+            """)
+            cursor.execute("""
+                CREATE TABLE bar (
+                    id serial PRIMARY KEY,
+                    other_id int,
+                    CONSTRAINT myconst FOREIGN KEY(other_id) REFERENCES foo(other_id)
+                );
+            """)
+
+    def tearDown(self):
+        with connection.cursor() as cursor:
+            cursor.execute("DROP TABLE bar;")
+            cursor.execute("DROP TABLE foo;")
+
+    def test_inspectdb_foreign_key_to_specific_field(self):
+        out = StringIO()
+        call_command('inspectdb', stdout=out)
+        output = out.getvalue()
+
+        # Check that the generated model for 'bar' has 'other_id' as a ForeignKey to 'foo(other_id)'
+        self.assertIn("other_id = models.ForeignKey(foo, to_field='other_id', on_delete=models.DO_NOTHING)", output)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/core/management/commands/inspectdb\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15037
cat coverage.cover
git checkout dab48b7482295956973879d15bfd4d3bb0718772
git apply /root/pre_state.patch
