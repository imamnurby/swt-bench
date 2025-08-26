#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 453967477e3ddae704cd739eac2449c0e13d464c >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 453967477e3ddae704cd739eac2449c0e13d464c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13401.py
new file mode 100644
index e69de29..6d74dd6 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13401.py
@@ -0,0 +1,27 @@
+from django.test import TestCase
+from django.db import models
+
+class AbstractModelA(models.Model):
+    class Meta:
+        abstract = True
+    myfield = models.IntegerField()
+
+class ConcreteModelB(AbstractModelA):
+    class Meta:
+        app_label = 'test_app'
+
+class ConcreteModelC(AbstractModelA):
+    class Meta:
+        app_label = 'test_app'
+
+class FieldEqualityTest(TestCase):
+    def test_field_equality_bug(self):
+        # Retrieve the field objects from both models
+        field_b = ConcreteModelB._meta.get_field('myfield')
+        field_c = ConcreteModelC._meta.get_field('myfield')
+
+        # Add the field objects to a set
+        field_set = {field_b, field_c}
+
+        # Assert that the length of the set is 2, indicating the bug is fixed
+        self.assertEqual(len(field_set), 2)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/fields/__init__\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13401
cat coverage.cover
git checkout 453967477e3ddae704cd739eac2449c0e13d464c
git apply /root/pre_state.patch
