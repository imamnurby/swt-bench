#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d87bd29c4f8dfcdf3f4a4eb8340e6770a2416fe3 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d87bd29c4f8dfcdf3f4a4eb8340e6770a2416fe3
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/backends/postgresql/client.py b/django/db/backends/postgresql/client.py
--- a/django/db/backends/postgresql/client.py
+++ b/django/db/backends/postgresql/client.py
@@ -17,6 +17,10 @@ def runshell_db(cls, conn_params):
         dbname = conn_params.get('database', '')
         user = conn_params.get('user', '')
         passwd = conn_params.get('password', '')
+        sslmode = conn_params.get('sslmode', '')
+        sslrootcert = conn_params.get('sslrootcert', '')
+        sslcert = conn_params.get('sslcert', '')
+        sslkey = conn_params.get('sslkey', '')
 
         if user:
             args += ['-U', user]
@@ -30,6 +34,14 @@ def runshell_db(cls, conn_params):
         subprocess_env = os.environ.copy()
         if passwd:
             subprocess_env['PGPASSWORD'] = str(passwd)
+        if sslmode:
+            subprocess_env['PGSSLMODE'] = str(sslmode)
+        if sslrootcert:
+            subprocess_env['PGSSLROOTCERT'] = str(sslrootcert)
+        if sslcert:
+            subprocess_env['PGSSLCERT'] = str(sslcert)
+        if sslkey:
+            subprocess_env['PGSSLKEY'] = str(sslkey)
         try:
             # Allow SIGINT to pass to psql to abort queries.
             signal.signal(signal.SIGINT, signal.SIG_IGN)

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11239.py
new file mode 100644
index e69de29..fae4ffc 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11239.py
@@ -0,0 +1,38 @@
+from django.test import TestCase
+from django.db import connections
+from unittest.mock import patch
+import subprocess
+
+class DbShellSSLTest(TestCase):
+    def test_dbshell_missing_ssl_params(self):
+        """
+        Test that dbshell correctly passes SSL parameters.
+        """
+        # Mock the connection parameters to include SSL options
+        ssl_options = {
+            'sslmode': 'verify-ca',
+            'sslrootcert': 'path/to/ca.crt',
+            'sslcert': 'path/to/client_cert_chain.crt',
+            'sslkey': 'path/to/client_key.key',
+        }
+        
+        with patch.dict('os.environ', {'PGPASSWORD': 'fakepassword'}):
+            with patch.object(connections['default'], 'get_connection_params', return_value={
+                'database': 'test_db',
+                'user': 'test_user',
+                'host': 'localhost',
+                'port': '5432',
+                **ssl_options,
+            }):
+                with patch('subprocess.run') as mock_run:
+                    # Set the mock to simulate a successful result
+                    mock_run.return_value = subprocess.CompletedProcess(args=[], returncode=0)
+                    
+                    # Attempt to run dbshell
+                    connections['default'].client.runshell()
+                    
+                    # Check that SSL parameters are passed to the subprocess
+                    called_args = mock_run.call_args[0][0] if mock_run.call_args else []
+                    self.assertIn('--sslrootcert=path/to/ca.crt', called_args)
+                    self.assertIn('--sslcert=path/to/client_cert_chain.crt', called_args)
+                    self.assertIn('--sslkey=path/to/client_key.key', called_args)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/backends/postgresql/client\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11239
cat coverage.cover
git checkout d87bd29c4f8dfcdf3f4a4eb8340e6770a2416fe3
git apply /root/pre_state.patch
