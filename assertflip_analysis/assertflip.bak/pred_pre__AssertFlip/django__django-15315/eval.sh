#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 652c68ffeebd510a6f59e1b56b3e007d07683ad8 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 652c68ffeebd510a6f59e1b56b3e007d07683ad8
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15315.py
new file mode 100644
index e69de29..fa8b2bb 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15315.py
@@ -0,0 +1,22 @@
+from django.test import SimpleTestCase
+from django.db import models
+
+class FieldHashTest(SimpleTestCase):
+    def test_field_hash_immutability(self):
+        # Step 1: Create a CharField and use it as a key in a dictionary
+        field = models.CharField(max_length=200)
+        initial_hash = hash(field)
+        field_dict = {field: 'initial'}
+
+        # Step 2: Assign the field to a model class
+        class Book(models.Model):
+            title = field
+
+            class Meta:
+                app_label = 'test_app'
+
+        # Step 3: Check if the hash has changed
+        new_hash = hash(field)
+
+        # Step 4: Assert that the hash has not changed, which is the correct behavior
+        self.assertEqual(initial_hash, new_hash)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/fields/__init__\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15315
cat coverage.cover
git checkout 652c68ffeebd510a6f59e1b56b3e007d07683ad8
git apply /root/pre_state.patch
