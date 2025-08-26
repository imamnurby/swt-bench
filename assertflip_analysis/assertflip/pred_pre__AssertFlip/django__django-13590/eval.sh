#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 755dbf39fcdc491fe9b588358303e259c7750be4 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 755dbf39fcdc491fe9b588358303e259c7750be4
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13590.py
new file mode 100644
index e69de29..3d83f03 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13590.py
@@ -0,0 +1,24 @@
+from django.test import SimpleTestCase
+from collections import namedtuple
+from django.db.models.sql.query import Query
+from django.db import models
+
+class DummyModel(models.Model):
+    class Meta:
+        app_label = 'test'
+
+class ResolveLookupValueTest(SimpleTestCase):
+    def test_named_tuple_causes_type_error(self):
+        # Define a named tuple with two elements
+        Point = namedtuple('Point', ['x', 'far'])
+        point_instance = Point(1, 2)
+
+        # Create a Query instance with a dummy model
+        query_instance = Query(DummyModel)
+
+        # Attempt to resolve the named tuple using resolve_lookup_value
+        try:
+            query_instance.resolve_lookup_value(point_instance, can_reuse=None, allow_joins=True)
+        except TypeError as e:
+            # Fail the test if a TypeError is raised
+            self.fail(f"TypeError was raised: {e}")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/sql/query\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13590
cat coverage.cover
git checkout 755dbf39fcdc491fe9b588358303e259c7750be4
git apply /root/pre_state.patch
