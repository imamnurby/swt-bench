#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 22a59c01c00cf9fbefaee0e8e67fab82bbaf1fd2 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 22a59c01c00cf9fbefaee0e8e67fab82bbaf1fd2
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13012.py
new file mode 100644
index e69de29..0737e64 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13012.py
@@ -0,0 +1,46 @@
+from django.test import TestCase
+from django.db import models
+from django.db.models import ExpressionWrapper, IntegerField, Sum, Value
+from django.db import connection
+
+class TestModel(models.Model):
+    column_a = models.IntegerField()
+    column_b = models.IntegerField()
+
+    class Meta:
+        app_label = 'test_app'
+
+class ExpressionWrapperGroupByTest(TestCase):
+    databases = {'default'}
+
+    @classmethod
+    def setUpTestData(cls):
+        # Create the table manually
+        with connection.cursor() as cursor:
+            cursor.execute('''
+                CREATE TABLE test_app_testmodel (
+                    id INTEGER PRIMARY KEY AUTOINCREMENT,
+                    column_a INTEGER NOT NULL,
+                    column_b INTEGER NOT NULL
+                )
+            ''')
+        TestModel.objects.create(column_a=1, column_b=10)
+        TestModel.objects.create(column_a=1, column_b=20)
+        TestModel.objects.create(column_a=2, column_b=30)
+
+    @classmethod
+    def tearDownClass(cls):
+        super().tearDownClass()
+        with connection.cursor() as cursor:
+            cursor.execute('DROP TABLE IF EXISTS test_app_testmodel')
+
+    def test_constant_expression_in_group_by(self):
+        expr = ExpressionWrapper(Value(3), output_field=IntegerField())
+        queryset = TestModel.objects.annotate(expr_res=expr).values('expr_res', 'column_a').annotate(sum=Sum('column_b'))
+
+        # Capture the generated SQL
+        sql, params = queryset.query.get_compiler('default').as_sql()
+
+        # Check if the constant expression is included in the GROUP BY clause
+        # We expect the constant to be correctly excluded once the bug is fixed
+        self.assertNotIn('GROUP BY "test_app_testmodel"."column_a", %s', sql)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/expressions\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13012
cat coverage.cover
git checkout 22a59c01c00cf9fbefaee0e8e67fab82bbaf1fd2
git apply /root/pre_state.patch
