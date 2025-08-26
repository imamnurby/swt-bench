#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d06c5b358149c02a62da8a5469264d05f29ac659 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d06c5b358149c02a62da8a5469264d05f29ac659
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14376.py
new file mode 100644
index e69de29..daadd03 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14376.py
@@ -0,0 +1,40 @@
+from django.test import SimpleTestCase
+from unittest.mock import MagicMock
+
+class MySQLBackendDeprecatedKwargsTest(SimpleTestCase):
+    def test_deprecated_kwargs_in_connection_params(self):
+        # Mock settings dictionary to simulate database configuration
+        settings_dict = {
+            'USER': 'test_user',
+            'NAME': 'test_db',
+            'PASSWORD': 'test_pass',
+            'HOST': 'localhost',
+            'PORT': '3306',
+        }
+
+        # Create a mock instance to simulate the behavior of BaseDatabaseWrapper
+        mock_instance = MagicMock()
+        mock_instance.settings_dict = settings_dict
+
+        # Simulate the get_connection_params method to return the kwargs
+        def mock_get_connection_params():
+            return {
+                'user': settings_dict['USER'],
+                'db': settings_dict['NAME'],  # BUG: 'db' is deprecated but currently used
+                'passwd': settings_dict['PASSWORD'],  # BUG: 'passwd' is deprecated but currently used
+                'host': settings_dict['HOST'],
+                'port': int(settings_dict['PORT']),
+            }
+
+        mock_instance.get_connection_params = mock_get_connection_params
+
+        # Get connection parameters
+        connection_params = mock_instance.get_connection_params()
+
+        # Assert that deprecated kwargs are not present
+        self.assertNotIn('db', connection_params)  # 'db' is deprecated and should not be used
+        self.assertNotIn('passwd', connection_params)  # 'passwd' is deprecated and should not be used
+
+        # Assert that the correct replacements are present
+        self.assertIn('database', connection_params)  # 'database' should be used instead
+        self.assertIn('password', connection_params)  # 'password' should be used instead

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/backends/mysql/base\.py|django/db/backends/mysql/client\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14376
cat coverage.cover
git checkout d06c5b358149c02a62da8a5469264d05f29ac659
git apply /root/pre_state.patch
