#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a7e7043c8746933dafce652507d3b821801cdc7d >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a7e7043c8746933dafce652507d3b821801cdc7d
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/migrations/autodetector.py b/django/db/migrations/autodetector.py
--- a/django/db/migrations/autodetector.py
+++ b/django/db/migrations/autodetector.py
@@ -96,7 +96,7 @@ def only_relation_agnostic_fields(self, fields):
         for name, field in sorted(fields.items()):
             deconstruction = self.deep_deconstruct(field)
             if field.remote_field and field.remote_field.model:
-                del deconstruction[2]['to']
+                deconstruction[2].pop('to', None)
             fields_def.append(deconstruction)
         return fields_def
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15104.py
new file mode 100644
index e69de29..f20af66 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15104.py
@@ -0,0 +1,27 @@
+from django.db import models
+from django.db.migrations.autodetector import MigrationAutodetector
+from django.db.migrations.state import ModelState, ProjectState
+from django.test import TestCase
+
+class CustomFKField(models.ForeignKey):
+    def __init__(self, *args, **kwargs):
+        kwargs['to'] = 'testapp.HardcodedModel'
+        super().__init__(*args, **kwargs)
+
+    def deconstruct(self):
+        name, path, args, kwargs = super().deconstruct()
+        del kwargs["to"]
+        return name, path, args, kwargs
+
+class ReproTestCase(TestCase):
+    def test_reproduction(self):
+        before = ProjectState()
+        before.add_model(ModelState('testapp', 'HardcodedModel', []))
+        
+        after = ProjectState()
+        after.add_model(ModelState('testapp', 'HardcodedModel', []))
+        after.add_model(ModelState('testapp', 'TestModel', [('custom', CustomFKField(on_delete=models.CASCADE))]))
+        
+        changes = MigrationAutodetector(before, after)._detect_changes()
+        # The test should fail if KeyError is raised, indicating the bug is present
+        self.assertEqual(len(changes['testapp']), 0)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/migrations/autodetector\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15104
cat coverage.cover
git checkout a7e7043c8746933dafce652507d3b821801cdc7d
git apply /root/pre_state.patch
