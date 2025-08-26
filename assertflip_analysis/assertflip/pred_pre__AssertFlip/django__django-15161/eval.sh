#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 96e7ff5e9ff6362d9a886545869ce4496ca4b0fb >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 96e7ff5e9ff6362d9a886545869ce4496ca4b0fb
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15161.py
new file mode 100644
index e69de29..f243c57 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15161.py
@@ -0,0 +1,37 @@
+from django.test import SimpleTestCase
+from django.utils.deconstruct import deconstructible
+from django.db.models.expressions import F, Case, When, Func
+from django.db.models import Q
+
+class ExpressionDeconstructionTests(SimpleTestCase):
+    def test_deconstruct_f_expression(self):
+        """
+        Test that F() deconstructs to the simplified path 'django.db.models.F'.
+        """
+        f_instance = F('field_name')
+        deconstructed_path, args, kwargs = f_instance.deconstruct()
+        self.assertEqual(deconstructed_path, 'django.db.models.F')
+
+    def test_deconstruct_case_expression(self):
+        """
+        Test that Case() deconstructs to a simplified path.
+        """
+        case_instance = Case()
+        deconstructed_path, args, kwargs = case_instance.deconstruct()
+        self.assertEqual(deconstructed_path, 'django.db.models.Case')
+
+    def test_deconstruct_when_expression(self):
+        """
+        Test that When() deconstructs to a simplified path.
+        """
+        when_instance = When(condition=Q(some_field__gt=0), then=1)
+        deconstructed_path, args, kwargs = when_instance.deconstruct()
+        self.assertEqual(deconstructed_path, 'django.db.models.When')
+
+    def test_deconstruct_func_expression(self):
+        """
+        Test that Func() deconstructs to a simplified path.
+        """
+        func_instance = Func()
+        deconstructed_path, args, kwargs = func_instance.deconstruct()
+        self.assertEqual(deconstructed_path, 'django.db.models.Func')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/expressions\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15161
cat coverage.cover
git checkout 96e7ff5e9ff6362d9a886545869ce4496ca4b0fb
git apply /root/pre_state.patch
