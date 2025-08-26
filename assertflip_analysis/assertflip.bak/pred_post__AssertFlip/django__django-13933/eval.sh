#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 42e8cf47c7ee2db238bf91197ea398126c546741 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 42e8cf47c7ee2db238bf91197ea398126c546741
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/forms/models.py b/django/forms/models.py
--- a/django/forms/models.py
+++ b/django/forms/models.py
@@ -1284,7 +1284,11 @@ def to_python(self, value):
                 value = getattr(value, key)
             value = self.queryset.get(**{key: value})
         except (ValueError, TypeError, self.queryset.model.DoesNotExist):
-            raise ValidationError(self.error_messages['invalid_choice'], code='invalid_choice')
+            raise ValidationError(
+                self.error_messages['invalid_choice'],
+                code='invalid_choice',
+                params={'value': value},
+            )
         return value
 
     def validate(self, value):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13933.py
new file mode 100644
index e69de29..bb31c5c 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13933.py
@@ -0,0 +1,35 @@
+from django.test import SimpleTestCase
+from django.core.exceptions import ValidationError
+from django.forms import ModelChoiceField
+from django.db import models
+
+# Define a simple model for testing
+class TestModel(models.Model):
+    name = models.CharField(max_length=100)
+
+    class Meta:
+        app_label = 'test'
+
+class ModelChoiceFieldTest(SimpleTestCase):
+    def setUp(self):
+        # Create a queryset with a single valid choice
+        self.queryset = TestModel.objects.all()
+
+    def test_invalid_choice_includes_value_in_error_message(self):
+        # Initialize ModelChoiceField with the queryset
+        field = ModelChoiceField(queryset=self.queryset)
+
+        # Invalid choice value
+        invalid_choice = 'invalid_choice_value'
+
+        # Attempt to convert the invalid choice to a Python object
+        with self.assertRaises(ValidationError) as cm:
+            field.to_python(invalid_choice)
+
+        # Capture the ValidationError
+        e = cm.exception
+
+        # Assert that the ValidationError is raised
+        self.assertEqual(e.code, 'invalid_choice')
+        # Assert that the error message includes the invalid choice value
+        self.assertIn(invalid_choice, e.message % {'value': invalid_choice})

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/forms/models\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13933
cat coverage.cover
git checkout 42e8cf47c7ee2db238bf91197ea398126c546741
git apply /root/pre_state.patch
