#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 6efc35b4fe3009666e56a60af0675d7d532bf4ff >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 6efc35b4fe3009666e56a60af0675d7d532bf4ff
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14170.py
new file mode 100644
index e69de29..c3c88c2 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14170.py
@@ -0,0 +1,33 @@
+from django.test import TestCase
+from django.db import models
+from django.db import connection
+from django.db.models.functions import ExtractIsoYear
+
+# Define a test model
+class DTModel(models.Model):
+    start_date = models.DateField()
+
+    class Meta:
+        app_label = 'test_app'
+
+class IsoYearLookupTest(TestCase):
+    databases = {'default'}
+
+    @classmethod
+    def setUpTestData(cls):
+        # Create the table manually since migrations are not applied
+        with connection.cursor() as cursor:
+            cursor.execute('CREATE TABLE test_app_dtmodel (id INTEGER PRIMARY KEY, start_date DATE)')
+
+        # Setup a test database with known dates
+        DTModel.objects.create(start_date='2020-01-01')
+        DTModel.objects.create(start_date='2020-12-31')
+        DTModel.objects.create(start_date='2021-01-01')
+
+    def test_iso_year_lookup_uses_between(self):
+        # Perform a query using __iso_year
+        qs = DTModel.objects.filter(start_date__iso_year=2020).only('id')
+        query = str(qs.query)
+
+        # Check if the query uses EXTRACT instead of BETWEEN
+        self.assertIn('EXTRACT', query)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/lookups\.py|django/db/backends/base/operations\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14170
cat coverage.cover
git checkout 6efc35b4fe3009666e56a60af0675d7d532bf4ff
git apply /root/pre_state.patch
