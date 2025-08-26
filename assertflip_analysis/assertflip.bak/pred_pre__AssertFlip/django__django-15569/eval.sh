#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 884b4c27f506b3c29d58509fc83a35c30ea10d94 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 884b4c27f506b3c29d58509fc83a35c30ea10d94
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15569.py
new file mode 100644
index e69de29..75f76fd 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15569.py
@@ -0,0 +1,22 @@
+from django.test import SimpleTestCase
+from django.db.models.query_utils import RegisterLookupMixin
+
+class MockLookup:
+    lookup_name = 'mock_lookup'
+
+class TestRegisterLookupMixin(SimpleTestCase):
+    def test_unregister_lookup_clears_cache(self):
+        class TestClass(RegisterLookupMixin):
+            pass
+
+        # Register the mock lookup
+        TestClass.register_lookup(MockLookup)
+        
+        # Verify the lookup is cached
+        self.assertIn('mock_lookup', TestClass.get_lookups())
+        
+        # Unregister the lookup
+        TestClass._unregister_lookup(MockLookup)
+        
+        # The lookup should not be retrievable after unregistering
+        self.assertNotIn('mock_lookup', TestClass.get_lookups())

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/query_utils\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15569
cat coverage.cover
git checkout 884b4c27f506b3c29d58509fc83a35c30ea10d94
git apply /root/pre_state.patch
