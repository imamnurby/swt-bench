#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 903aaa35e5ceaa33bfc9b19b7f6da65ce5a91dd4 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 903aaa35e5ceaa33bfc9b19b7f6da65ce5a91dd4
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/forms/models.py b/django/forms/models.py
--- a/django/forms/models.py
+++ b/django/forms/models.py
@@ -1166,6 +1166,9 @@ def __init__(self, value, instance):
     def __str__(self):
         return str(self.value)
 
+    def __hash__(self):
+        return hash(self.value)
+
     def __eq__(self, other):
         if isinstance(other, ModelChoiceIteratorValue):
             other = other.value

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14915.py
new file mode 100644
index e69de29..c45756d 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14915.py
@@ -0,0 +1,16 @@
+from django.test import SimpleTestCase
+from django.forms.models import ModelChoiceIteratorValue
+
+class ModelChoiceIteratorValueHashableTest(SimpleTestCase):
+    def test_model_choice_iterator_value_unhashable(self):
+        """
+        Test that using ModelChoiceIteratorValue as a dictionary key does not raise TypeError.
+        """
+        value_instance = ModelChoiceIteratorValue(value=1, instance=None)
+        
+        try:
+            # Attempt to use ModelChoiceIteratorValue as a dictionary key
+            test_dict = {value_instance: "test"}
+        except TypeError as e:
+            # If a TypeError is raised, the test should fail
+            self.fail(f"ModelChoiceIteratorValue should be hashable, but raised TypeError: {str(e)}")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/forms/models\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14915
cat coverage.cover
git checkout 903aaa35e5ceaa33bfc9b19b7f6da65ce5a91dd4
git apply /root/pre_state.patch
