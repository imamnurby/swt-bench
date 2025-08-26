#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 6866c91b638de5368c18713fa851bfe56253ea55 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 6866c91b638de5368c18713fa851bfe56253ea55
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11299.py
new file mode 100644
index e69de29..39fe783 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11299.py
@@ -0,0 +1,52 @@
+from django.db import models
+from django.test import SimpleTestCase, override_settings
+from django.db import connection
+from django.db.models import Q
+from django.apps import apps as global_apps
+from django.core.management import call_command
+from io import StringIO
+
+@override_settings(INSTALLED_APPS=['django.contrib.contenttypes'])
+class CheckConstraintSQLTest(SimpleTestCase):
+    databases = {'default'}
+
+    def test_check_constraint_sql_generation(self):
+        class TestConstraint(models.Model):
+            field_1 = models.IntegerField(blank=True, null=True)
+            flag = models.BooleanField(blank=False, null=False)
+
+            class Meta:
+                app_label = 'test_app'
+                constraints = [
+                    models.CheckConstraint(
+                        check=Q(flag__exact=True, field_1__isnull=False) |
+                              Q(flag__exact=False),
+                        name='field_1_has_value_if_flag_set',
+                    ),
+                ]
+
+        # Register the model to the global app registry
+        if 'test_app' in global_apps.all_models:
+            del global_apps.all_models['test_app']
+        global_apps.register_model('test_app', TestConstraint)
+
+        # Capture the output of the migration
+        out = StringIO()
+        with connection.schema_editor() as schema_editor:
+            # Create the table directly using schema_editor to avoid migration issues
+            schema_editor.create_model(TestConstraint)
+            # Capture the SQL for the constraint
+            constraint = TestConstraint._meta.constraints[0]
+            sql = constraint.create_sql(TestConstraint, schema_editor)
+
+        # Convert the SQL statement to a string for assertion
+        sql_str = str(sql)
+
+        # The SQL should not include fully qualified field names
+        # This assertion is expected to fail if the bug is present
+        self.assertNotIn('"test_app_testconstraint"."field_1"', sql_str)
+
+    def tearDown(self):
+        # Clean up the model registration to avoid conflicts in subsequent tests
+        if 'test_app' in global_apps.all_models:
+            del global_apps.all_models['test_app']

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/sql/query\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11299
cat coverage.cover
git checkout 6866c91b638de5368c18713fa851bfe56253ea55
git apply /root/pre_state.patch
