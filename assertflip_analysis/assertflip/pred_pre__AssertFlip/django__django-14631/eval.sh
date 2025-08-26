#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 84400d2e9db7c51fee4e9bb04c028f665b8e7624 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 84400d2e9db7c51fee4e9bb04c028f665b8e7624
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14631.py
new file mode 100644
index e69de29..7791a19 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14631.py
@@ -0,0 +1,32 @@
+from django.test import SimpleTestCase
+from django.forms import Form, CharField
+
+class TestForm(Form):
+    name = CharField(initial='Initial Name')
+    age = CharField(initial='Initial Age', disabled=True)
+
+class BaseFormTest(SimpleTestCase):
+    def test_clean_fields_vs_changed_data(self):
+        # Setup initial data and user-provided data
+        initial_data = {'name': 'Initial Name', 'age': 'Initial Age'}
+        user_data = {'name': 'Changed Name', 'age': 'Initial Age'}
+
+        # Initialize the form with initial data and user-provided data
+        form = TestForm(data=user_data, initial=initial_data)
+
+        # Call full_clean to ensure cleaned_data is populated
+        form.full_clean()
+
+        # Access cleaned_data and changed_data
+        cleaned_data_name = form.cleaned_data['name']
+        cleaned_data_age = form.cleaned_data['age']
+        changed_data = form.changed_data
+
+        # Assert that cleaned_data for 'age' matches the initial value accessed through BoundField
+        self.assertNotEqual(cleaned_data_age, form['age'].initial)
+        # This assertion should fail due to the bug
+
+        # Assert that changed_data correctly identifies fields that have changed
+        self.assertIn('name', changed_data)
+        self.assertIn('age', changed_data)
+        # This assertion should fail because 'age' should not be in changed_data

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/forms/forms\.py|django/forms/boundfield\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14631
cat coverage.cover
git checkout 84400d2e9db7c51fee4e9bb04c028f665b8e7624
git apply /root/pre_state.patch
