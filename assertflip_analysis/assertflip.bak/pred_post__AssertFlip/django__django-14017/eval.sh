#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 466920f6d726eee90d5566e0a9948e92b33a122e >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 466920f6d726eee90d5566e0a9948e92b33a122e
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/models/query_utils.py b/django/db/models/query_utils.py
--- a/django/db/models/query_utils.py
+++ b/django/db/models/query_utils.py
@@ -40,7 +40,7 @@ def __init__(self, *args, _connector=None, _negated=False, **kwargs):
         super().__init__(children=[*args, *sorted(kwargs.items())], connector=_connector, negated=_negated)
 
     def _combine(self, other, conn):
-        if not isinstance(other, Q):
+        if not(isinstance(other, Q) or getattr(other, 'conditional', False) is True):
             raise TypeError(other)
 
         # If the other Q() is empty, ignore it and just use `self`.

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14017.py
new file mode 100644
index e69de29..eff0191 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14017.py
@@ -0,0 +1,28 @@
+from django.test import SimpleTestCase
+from django.db.models import Exists, Q
+from django.contrib.auth.models import User  # Using User model for testing
+
+class QExistsCommutativeTest(SimpleTestCase):
+    def test_q_exists_commutative(self):
+        """
+        Test the commutative property of the & operator between Q and Exists.
+        """
+        # Create a Q object
+        q_object = Q()
+
+        # Create an Exists object using the User model
+        exists_object = Exists(User.objects.all())
+
+        # Test Exists & Q - should not raise an error
+        try:
+            result = exists_object & q_object
+            self.assertIsInstance(result, Q)
+        except TypeError:
+            self.fail("Exists & Q raised TypeError unexpectedly")
+
+        # Test Q & Exists - should not raise a TypeError
+        try:
+            result = q_object & exists_object
+            self.assertIsInstance(result, Q)
+        except TypeError:
+            self.fail("Q & Exists raised TypeError unexpectedly")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/query_utils\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14017
cat coverage.cover
git checkout 466920f6d726eee90d5566e0a9948e92b33a122e
git apply /root/pre_state.patch
