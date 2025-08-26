#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD bd366ca2aeffa869b7dbc0b0aa01caea75e6dc31 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff bd366ca2aeffa869b7dbc0b0aa01caea75e6dc31
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16527.py
new file mode 100644
index e69de29..1f3ab4b 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16527.py
@@ -0,0 +1,28 @@
+from django.test import SimpleTestCase
+from django.template.context import Context
+from django.contrib.admin.templatetags.admin_modify import submit_row
+
+class SubmitRowTests(SimpleTestCase):
+    def test_show_save_as_new_without_add_permission(self):
+        # Context setup: user has change permission but not add permission
+        context = {
+            'add': False,
+            'change': True,
+            'is_popup': False,
+            'save_as': True,
+            'has_add_permission': False,
+            'has_change_permission': True,
+            'has_view_permission': True,
+            'has_editable_inline_admin_formsets': False,
+            'has_delete_permission': True,
+            'show_delete': True,
+            'show_save': True,
+            'show_save_and_add_another': True,
+            'show_save_and_continue': True,
+        }
+
+        # Call the submit_row function with the context
+        result_context = submit_row(context)
+
+        # Assert that "show_save_as_new" is False, which is the correct behavior
+        self.assertFalse(result_context['show_save_as_new'])

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/admin/templatetags/admin_modify\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16527
cat coverage.cover
git checkout bd366ca2aeffa869b7dbc0b0aa01caea75e6dc31
git apply /root/pre_state.patch
