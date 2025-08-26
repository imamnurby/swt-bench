#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 859a87d873ce7152af73ab851653b4e1c3ffea4c >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 859a87d873ce7152af73ab851653b4e1c3ffea4c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15503.py
new file mode 100644
index e69de29..14cc80e 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15503.py
@@ -0,0 +1,49 @@
+from django.test import TestCase
+from django.test.utils import override_settings
+from django.db import models, connection
+
+# Define the model with JSONField
+class JsonFieldHasKeyTest(models.Model):
+    data = models.JSONField()
+
+    class Meta:
+        app_label = 'tests'  # Use 'tests' as the app label to avoid KeyError
+
+# Test case for the issue
+@override_settings(DATABASES={
+    'default': {
+        'ENGINE': 'django.db.backends.sqlite3',
+        'NAME': ':memory:',  # Use in-memory database for testing
+    }
+})
+class JsonFieldHasKeyTestCase(TestCase):
+    @classmethod
+    def setUpClass(cls):
+        super().setUpClass()
+        # Create the table manually since migrations are not applied in-memory
+        with connection.cursor() as cursor:
+            cursor.execute('PRAGMA foreign_keys = OFF;')
+            cursor.execute('''
+                CREATE TABLE tests_jsonfieldhaskeytest (
+                    id INTEGER PRIMARY KEY AUTOINCREMENT,
+                    data JSON NOT NULL
+                );
+            ''')
+            cursor.execute('PRAGMA foreign_keys = ON;')
+
+    def setUp(self):
+        # Insert test data with numeric keys
+        JsonFieldHasKeyTest.objects.create(data={'foo': 'bar'})
+        JsonFieldHasKeyTest.objects.create(data={'1111': 'bar'})
+
+    def test_json_field_has_key(self):
+        # Perform has_key lookup for numeric keys
+        c1 = JsonFieldHasKeyTest.objects.filter(data__has_key='foo').count()
+        c2 = JsonFieldHasKeyTest.objects.filter(data__has_key='1111').count()
+        
+        # Assert that the count of found entries with the string key is 1
+        self.assertEqual(c1, 1, "Should have found 1 entry with key 'foo'")
+        
+        # Assert that the count of found entries with the numeric key is 1
+        self.assertEqual(c2, 1, "Should have found 1 entry with key '1111'")
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/fields/json\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15503
cat coverage.cover
git checkout 859a87d873ce7152af73ab851653b4e1c3ffea4c
git apply /root/pre_state.patch
