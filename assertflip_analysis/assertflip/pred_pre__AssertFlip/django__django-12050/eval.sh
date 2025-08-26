#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD b93a0e34d9b9b99d41103782b7e7aeabf47517e3 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff b93a0e34d9b9b99d41103782b7e7aeabf47517e3
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-12050.py
new file mode 100644
index e69de29..c57e186 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-12050.py
@@ -0,0 +1,32 @@
+from django.test import SimpleTestCase
+from django.db.models.lookups import Lookup
+
+class MockField:
+    def __init__(self):
+        self.output_field = self
+
+    def get_prep_value(self, value):
+        return value
+
+class TestLookup(SimpleTestCase):
+    def test_resolve_lookup_value_coercion(self):
+        class MockLookup(Lookup):
+            lookup_name = 'exact'
+            prepare_rhs = True
+
+            def get_prep_lookup(self):
+                if isinstance(self.rhs, list):
+                    # Simulate the bug: coerce list to tuple
+                    return tuple(self.rhs)
+                return self.rhs
+
+        # Create a mock field and a MockLookup instance with a list as rhs
+        mock_field = MockField()
+        input_value = [1, 2, 3]  # Input is a list
+        mock_lookup = MockLookup(mock_field, input_value)
+
+        # Call get_prep_lookup to trigger the bug
+        prepared_rhs = mock_lookup.get_prep_lookup()
+
+        # Assert that the prepared RHS is a list, which is the correct behavior
+        self.assertIsInstance(prepared_rhs, list)  # Correct behavior: should be a list

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/models/sql/query\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-12050
cat coverage.cover
git checkout b93a0e34d9b9b99d41103782b7e7aeabf47517e3
git apply /root/pre_state.patch
