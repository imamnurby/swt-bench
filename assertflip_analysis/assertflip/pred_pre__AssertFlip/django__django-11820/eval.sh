#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD c2678e49759e5c4c329bff0eeca2886267005d21 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff c2678e49759e5c4c329bff0eeca2886267005d21
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11820.py
new file mode 100644
index e69de29..0040ad9 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11820.py
@@ -0,0 +1,27 @@
+from django.test import SimpleTestCase
+from django.db import models
+from django.core.checks import Error
+
+class ParentModel(models.Model):
+    name = models.CharField(max_length=100)
+
+    class Meta:
+        app_label = 'test_app'
+
+class ChildModel(models.Model):
+    parent = models.ForeignKey(ParentModel, on_delete=models.CASCADE)
+
+    class Meta:
+        ordering = ['parent__pk']
+        app_label = 'test_app'
+
+class OrderingValidationTest(SimpleTestCase):
+    def test_ordering_with_related_pk(self):
+        """
+        Test that models.E015 is incorrectly raised when Meta.ordering contains __pk of a related field.
+        """
+        errors = ChildModel.check()
+        error_ids = [error.id for error in errors]
+
+        # Assert that models.E015 is not raised, which is the correct behavior
+        self.assertNotIn('models.E015', error_ids)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/base\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11820
cat coverage.cover
git checkout c2678e49759e5c4c329bff0eeca2886267005d21
git apply /root/pre_state.patch
