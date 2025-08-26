#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 7d5329852f19c6ae78c6f6f3d3e41835377bf295 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 7d5329852f19c6ae78c6f6f3d3e41835377bf295
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16315.py
new file mode 100644
index e69de29..a6110c1 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16315.py
@@ -0,0 +1,63 @@
+from django.test import TestCase
+from django.db import models, connection
+from django.db import connections
+
+# Define a test model within a test app context
+class TestModelWithDbColumn(models.Model):
+    class Meta:
+        app_label = 'test_app'
+        db_table = "Activity_BlackListed"
+    blacklistid = models.IntegerField(primary_key=True, db_column="BlacklistID")
+    sectorid = models.IntegerField(null=True, blank=True, db_column="SectorID")
+
+class TestBulkCreateWithUpdateConflicts(TestCase):
+    databases = {'default'}
+
+    @classmethod
+    def setUpTestData(cls):
+        # Create the table manually since migrations are not applied
+        with connection.cursor() as cursor:
+            cursor.execute('''
+                CREATE TABLE Activity_BlackListed (
+                    BlacklistID INTEGER PRIMARY KEY,
+                    SectorID INTEGER
+                )
+            ''')
+
+    @classmethod
+    def tearDownClass(cls):
+        # Drop the table after the test
+        with connection.cursor() as cursor:
+            cursor.execute('DROP TABLE Activity_BlackListed')
+        super().tearDownClass()
+
+    def test_bulk_create_with_mixed_case_db_columns(self):
+        # Create instances of the model
+        instances = [
+            TestModelWithDbColumn(blacklistid=1, sectorid=10),
+            TestModelWithDbColumn(blacklistid=2, sectorid=20),
+        ]
+
+        # Capture the SQL query generated during bulk_create
+        with connection.cursor() as cursor:
+            # Enable query logging
+            connection.force_debug_cursor = True
+
+            try:
+                TestModelWithDbColumn.objects.bulk_create(
+                    instances,
+                    update_conflicts=True,
+                    update_fields=["sectorid"],
+                    unique_fields=["blacklistid"]
+                )
+            except Exception:
+                pass
+
+            # Retrieve the last executed SQL query
+            sql_query = connection.queries[-1]['sql'] if connection.queries else None
+
+        # Assert that the ON CONFLICT clause uses db_column names instead of field names
+        # This is the correct behavior we are expecting
+        self.assertIsNotNone(sql_query)
+        self.assertIn('ON CONFLICT("BlacklistID")', sql_query)
+        self.assertIn('DO UPDATE SET "SectorID" = EXCLUDED."SectorID"', sql_query)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/query\.py|django/db/models/sql/compiler\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16315
cat coverage.cover
git checkout 7d5329852f19c6ae78c6f6f3d3e41835377bf295
git apply /root/pre_state.patch
