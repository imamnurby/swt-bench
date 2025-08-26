#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 9c92924cd5d164701e2514e1c2d6574126bd7cc2 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 9c92924cd5d164701e2514e1c2d6574126bd7cc2
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13346.py
new file mode 100644
index e69de29..8104cc6 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13346.py
@@ -0,0 +1,38 @@
+from django.test import TestCase
+from django.db import models, connection
+
+class JSONFieldInLookupTest(TestCase):
+    databases = {'default'}
+
+    @classmethod
+    def setUpTestData(cls):
+        # Define the model within the test class to ensure it is created
+        class TestModel(models.Model):
+            our_field = models.JSONField()
+
+            class Meta:
+                app_label = 'myapp'
+
+        cls.TestModel = TestModel
+
+        # Create the table for the model
+        with connection.cursor() as cursor:
+            cursor.execute('CREATE TABLE myapp_testmodel (id INTEGER PRIMARY KEY AUTOINCREMENT, our_field JSON);')
+
+        # Insert test data with 'our_field' containing a key with a value of 0
+        cls.TestModel.objects.create(our_field={'key': 0})
+        cls.TestModel.objects.create(our_field={'key': 0})
+        cls.TestModel.objects.create(our_field={'key': 0})
+        cls.TestModel.objects.create(our_field={'key': 1})
+
+    def test_in_lookup_on_key_transform(self):
+        # Test with __in lookup on key transform
+        first_filter = {'our_field__key__in': [0]}
+        first_items = self.TestModel.objects.filter(**first_filter)
+        # Assert that the correct behavior occurs
+        self.assertEqual(len(first_items), 3)  # This should return 3 items as expected
+
+        # Control test to show that the key lookup works without __in
+        second_filter = {'our_field__key': 0}
+        second_items = self.TestModel.objects.filter(**second_filter)
+        self.assertEqual(len(second_items), 3)  # This should return 3 items as expected

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/fields/json\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13346
cat coverage.cover
git checkout 9c92924cd5d164701e2514e1c2d6574126bd7cc2
git apply /root/pre_state.patch
