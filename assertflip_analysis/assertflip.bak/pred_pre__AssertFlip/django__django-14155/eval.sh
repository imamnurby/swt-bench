#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 2f13c476abe4ba787b6cb71131818341911f43cc >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 2f13c476abe4ba787b6cb71131818341911f43cc
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14155.py
new file mode 100644
index e69de29..cab4330 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14155.py
@@ -0,0 +1,31 @@
+from django.test import SimpleTestCase
+from django.urls.resolvers import ResolverMatch
+import functools
+
+class ResolverMatchReprTest(SimpleTestCase):
+    def test_repr_with_partial_function(self):
+        # Define a simple function to use with functools.partial
+        def sample_function(x, y):
+            return x + y
+
+        # Create a partial function with one argument fixed
+        partial_func = functools.partial(sample_function, x=1)
+
+        # Instantiate ResolverMatch with the partial function
+        resolver_match = ResolverMatch(
+            func=partial_func,
+            args=(),
+            kwargs={},
+            url_name=None,
+            app_names=None,
+            namespaces=None,
+            route=None,
+            tried=None
+        )
+
+        # Get the __repr__ output
+        repr_output = repr(resolver_match)
+
+        # Assert that the __repr__ output includes the underlying function and arguments
+        self.assertIn("sample_function", repr_output)
+        self.assertIn("x=1", repr_output)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/urls/resolvers\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14155
cat coverage.cover
git checkout 2f13c476abe4ba787b6cb71131818341911f43cc
git apply /root/pre_state.patch
