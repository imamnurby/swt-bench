#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 312049091288dbba2299de8d07ea3e3311ed7238 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 312049091288dbba2299de8d07ea3e3311ed7238
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11951.py
new file mode 100644
index e69de29..f4d3e8d 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11951.py
@@ -0,0 +1,31 @@
+from django.test import SimpleTestCase
+from unittest.mock import patch
+
+class MockModel:
+    def __init__(self, name):
+        self.name = name
+        self.pk = None
+
+class BulkCreateBatchSizeTest(SimpleTestCase):
+    def test_bulk_create_with_oversized_batch_size(self):
+        # Mock objects to be inserted
+        objs = [MockModel(name=f"Object {i}") for i in range(100)]
+
+        # Define a batch_size larger than the maximum compatible batch size
+        oversized_batch_size = 1000  # Assuming the max compatible batch size is less than this
+        max_compatible_batch_size = 500  # Example max compatible batch size
+
+        # Mock the _batched_insert method to simulate the behavior
+        with patch('django.db.models.query.QuerySet._batched_insert') as mock_batched_insert:
+            # Simulate the bulk_create call
+            mock_batched_insert.return_value = [(None,)] * len(objs)
+
+            # Call the bulk_create method
+            # This is where the bug occurs: the oversized batch_size is used directly
+            # We expect the method to adjust the batch_size to the maximum compatible batch size
+            mock_batched_insert(objs, [], oversized_batch_size, ignore_conflicts=False)
+
+            # Assert that the _batched_insert was called with the adjusted batch_size
+            mock_batched_insert.assert_called_with(objs, [], max_compatible_batch_size, ignore_conflicts=False)
+
+            # The test should fail if the oversized batch_size is used directly

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/query\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11951
cat coverage.cover
git checkout 312049091288dbba2299de8d07ea3e3311ed7238
git apply /root/pre_state.patch
