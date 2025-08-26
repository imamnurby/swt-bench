#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD c84b91b7603e488f7171fdff8f08368ef3d6b856 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff c84b91b7603e488f7171fdff8f08368ef3d6b856
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11138.py
new file mode 100644
index e69de29..b2d9cb3 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11138.py
@@ -0,0 +1,52 @@
+from django.test import SimpleTestCase
+from django.test.utils import override_settings
+from django.utils import timezone
+from django.db import models, connection
+import datetime
+
+class MyModel(models.Model):
+    my_datetime_field = models.DateTimeField()
+
+    class Meta:
+        app_label = 'test_app'
+
+@override_settings(USE_TZ=True, TIME_ZONE='Europe/Paris', DATABASES={
+    'default': {
+        'ENGINE': 'django.db.backends.mysql',
+        'NAME': 'test_db',
+        'USER': 'test_user',
+        'PASSWORD': 'test_password',
+        'HOST': 'localhost',
+        'PORT': '3306',
+        'OPTIONS': {
+            'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
+        },
+        'TIME_ZONE': 'Europe/Paris',
+    }
+})
+class TimeZoneTestCase(SimpleTestCase):
+    databases = {'default'}
+
+    @classmethod
+    def setUpClass(cls):
+        super().setUpClass()
+        # Create the model table using migrations
+        with connection.schema_editor() as schema_editor:
+            schema_editor.create_model(MyModel)
+        
+        # Insert a timezone-aware datetime object
+        MyModel.objects.create(my_datetime_field=timezone.make_aware(datetime.datetime(2017, 7, 6, 20, 50)))
+
+    def test_date_lookup_bug(self):
+        """
+        Test that date lookup considers the database TIME_ZONE setting.
+        This test should pass, but it exposes the bug where the conversion is done from UTC to the app timezone
+        instead of from the database timezone to the app timezone.
+        """
+        dt = timezone.make_aware(datetime.datetime(2017, 7, 6, 20, 50), timezone=timezone.get_current_timezone())
+        
+        # Direct equality filter should return True
+        self.assertTrue(MyModel.objects.filter(my_datetime_field=dt).exists())
+
+        # Date lookup filter should return True, but due to the bug, it returns False
+        self.assertFalse(MyModel.objects.filter(my_datetime_field__date=dt.date()).exists())

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/backends/sqlite3/operations\.py|django/db/backends/mysql/operations\.py|django/db/backends/oracle/operations\.py|django/db/backends/sqlite3/base\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11138
cat coverage.cover
git checkout c84b91b7603e488f7171fdff8f08368ef3d6b856
git apply /root/pre_state.patch
