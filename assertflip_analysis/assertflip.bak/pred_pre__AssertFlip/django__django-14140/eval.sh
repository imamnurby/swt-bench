#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 45814af6197cfd8f4dc72ee43b90ecde305a1d5a >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 45814af6197cfd8f4dc72ee43b90ecde305a1d5a
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14140.py
new file mode 100644
index e69de29..e79eb25 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14140.py
@@ -0,0 +1,18 @@
+from django.test import TestCase
+from django.db.models import Q, Exists
+from django.contrib.auth import get_user_model
+
+class QDeconstructBugTest(TestCase):
+    def test_deconstruct_with_exists_child(self):
+        """
+        Test deconstructing a Q object with a single Exists child.
+        This should not raise a TypeError once the bug is fixed.
+        """
+        user_model = get_user_model()
+        exists_expression = Exists(user_model.objects.filter(username='jim'))
+        q_object = Q(exists_expression)
+
+        try:
+            q_object.deconstruct()
+        except TypeError as e:
+            self.fail(f"TypeError raised: {e}")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/query_utils\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14140
cat coverage.cover
git checkout 45814af6197cfd8f4dc72ee43b90ecde305a1d5a
git apply /root/pre_state.patch
