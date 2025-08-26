#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 4e8121e8e42a24acc3565851c9ef50ca8322b15c >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 4e8121e8e42a24acc3565851c9ef50ca8322b15c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/migrations/state.py b/django/db/migrations/state.py
--- a/django/db/migrations/state.py
+++ b/django/db/migrations/state.py
@@ -91,10 +91,11 @@ class ProjectState:
     def __init__(self, models=None, real_apps=None):
         self.models = models or {}
         # Apps to include from main registry, usually unmigrated ones
-        if real_apps:
-            self.real_apps = real_apps if isinstance(real_apps, set) else set(real_apps)
+        if real_apps is None:
+            real_apps = set()
         else:
-            self.real_apps = set()
+            assert isinstance(real_apps, set)
+        self.real_apps = real_apps
         self.is_delayed = False
         # {remote_model_key: {model_key: [(field_name, field)]}}
         self.relations = None

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-14765.py
new file mode 100644
index e69de29..fe99943 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-14765.py
@@ -0,0 +1,16 @@
+from django.test import SimpleTestCase
+from django.db.migrations.state import ProjectState
+
+class ProjectStateInitTests(SimpleTestCase):
+    def test_real_apps_conversion(self):
+        """
+        Test ProjectState.__init__() with non-set real_apps argument.
+        """
+
+        # Non-set input for real_apps
+        real_apps_input = ['app1', 'app2']
+
+        # Instantiate ProjectState with a list as real_apps
+        # Expecting an error or assertion since real_apps should be a set
+        with self.assertRaises(AssertionError):
+            ProjectState(real_apps=real_apps_input)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/migrations/state\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-14765
cat coverage.cover
git checkout 4e8121e8e42a24acc3565851c9ef50ca8322b15c
git apply /root/pre_state.patch
