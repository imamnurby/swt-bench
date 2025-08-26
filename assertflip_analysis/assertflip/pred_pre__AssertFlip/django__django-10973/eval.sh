#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD ddb293685235fd09e932805771ae97f72e817181 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff ddb293685235fd09e932805771ae97f72e817181
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-10973.py
new file mode 100644
index e69de29..30db560 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-10973.py
@@ -0,0 +1,37 @@
+from django.test import SimpleTestCase
+from unittest.mock import patch, MagicMock
+import os
+from django.db.backends.postgresql.client import DatabaseClient
+
+class DatabaseClientTest(SimpleTestCase):
+    @patch('django.db.backends.postgresql.client.subprocess.check_call')
+    @patch('django.db.backends.postgresql.client.NamedTemporaryFile')
+    @patch('django.db.backends.postgresql.client.os.environ', {})
+    def test_runshell_db_with_pgpassword(self, mock_tempfile, mock_subprocess):
+        # Mock the NamedTemporaryFile to simulate the creation of a .pgpass file
+        mock_temp_file = MagicMock()
+        mock_temp_file.name = '/fake/path/to/.pgpass'
+        mock_tempfile.return_value = mock_temp_file
+
+        conn_params = {
+            'host': 'localhost',
+            'port': '5432',
+            'database': 'testdb',
+            'user': 'testuser',
+            'password': 'testpassword'
+        }
+        
+        # Set PGPASSWORD in the environment to simulate the correct behavior
+        os.environ['PGPASSWORD'] = conn_params['password']
+        
+        DatabaseClient.runshell_db(conn_params)
+        
+        # Check that subprocess.check_call was called with the expected arguments
+        mock_subprocess.assert_called_once()
+        
+        # Assert that 'PGPASSWORD' is set in the environment
+        self.assertNotIn('PGPASSWORD', os.environ)
+        
+        # Clean up the environment variable
+        if 'PGPASSWORD' in os.environ:
+            del os.environ['PGPASSWORD']

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/backends/postgresql/client\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-10973
cat coverage.cover
git checkout ddb293685235fd09e932805771ae97f72e817181
git apply /root/pre_state.patch
