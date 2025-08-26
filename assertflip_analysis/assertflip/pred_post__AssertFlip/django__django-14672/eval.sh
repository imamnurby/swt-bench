#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 00ea883ef56fb5e092cbe4a6f7ff2e7470886ac4 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 00ea883ef56fb5e092cbe4a6f7ff2e7470886ac4
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/models/fields/reverse_related.py b/django/db/models/fields/reverse_related.py
--- a/django/db/models/fields/reverse_related.py
+++ b/django/db/models/fields/reverse_related.py
@@ -310,7 +310,7 @@ def __init__(self, field, to, related_name=None, related_query_name=None,
     def identity(self):
         return super().identity + (
             self.through,
-            self.through_fields,
+            make_hashable(self.through_fields),
             self.db_constraint,
         )
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14672.py
new file mode 100644
index e69de29..4211028 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14672.py
@@ -0,0 +1,47 @@
+from django.test import TestCase
+from django.db import models
+
+class Parent(models.Model):
+    name = models.CharField(max_length=256)
+
+    class Meta:
+        app_label = 'test_app'
+
+class ProxyParent(Parent):
+    class Meta:
+        proxy = True
+        app_label = 'test_app'
+
+class Child(models.Model):
+    parent = models.ForeignKey(Parent, on_delete=models.CASCADE)
+    many_to_many_field = models.ManyToManyField(
+        to=Parent,
+        through="ManyToManyModel",
+        through_fields=['child', 'parent'],
+        related_name="something"
+    )
+
+    class Meta:
+        app_label = 'test_app'
+
+class ManyToManyModel(models.Model):
+    parent = models.ForeignKey(Parent, on_delete=models.CASCADE, related_name='+')
+    child = models.ForeignKey(Child, on_delete=models.CASCADE, related_name='+')
+    second_child = models.ForeignKey(Child, on_delete=models.CASCADE, null=True, default=None)
+
+    class Meta:
+        app_label = 'test_app'
+
+class ManyToManyRelTest(TestCase):
+    def test_unhashable_through_fields(self):
+        """
+        Test that the identity property of ManyToManyRel includes hashable 'through_fields'.
+        """
+        rel = Child._meta.get_field('many_to_many_field').remote_field
+        identity = rel.identity
+
+        # Correct behavior: identity should be hashable
+        try:
+            hash(identity)
+        except TypeError:
+            self.fail("identity should be hashable but raised TypeError")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/fields/reverse_related\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14672
cat coverage.cover
git checkout 00ea883ef56fb5e092cbe4a6f7ff2e7470886ac4
git apply /root/pre_state.patch
