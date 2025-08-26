#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 18759b2209ff556aed7f20d83cbf23e3d234e41c >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 18759b2209ff556aed7f20d83cbf23e3d234e41c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/migrations/autodetector.py b/django/db/migrations/autodetector.py
--- a/django/db/migrations/autodetector.py
+++ b/django/db/migrations/autodetector.py
@@ -563,6 +563,16 @@ def generate_created_models(self):
                 if isinstance(base, str) and "." in base:
                     base_app_label, base_name = base.split(".", 1)
                     dependencies.append((base_app_label, base_name, None, True))
+                    # Depend on the removal of base fields if the new model has
+                    # a field with the same name.
+                    old_base_model_state = self.from_state.models.get((base_app_label, base_name))
+                    new_base_model_state = self.to_state.models.get((base_app_label, base_name))
+                    if old_base_model_state and new_base_model_state:
+                        removed_base_fields = set(old_base_model_state.fields).difference(
+                            new_base_model_state.fields,
+                        ).intersection(model_state.fields)
+                        for removed_base_field in removed_base_fields:
+                            dependencies.append((base_app_label, base_name, removed_base_field, False))
             # Depend on the other end of the primary key if it's a relation
             if primary_key_rel:
                 dependencies.append((

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-12754.py
new file mode 100644
index e69de29..38ae6b7 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-12754.py
@@ -0,0 +1,63 @@
+from django.test import TestCase
+from django.core.management import call_command
+from django.db import models
+from django.db.migrations.state import ProjectState
+from django.db.migrations.migration import Migration
+from django.db.migrations.operations.models import CreateModel, RemoveField
+from django.db.migrations.state import ModelState
+
+class MigrationTestCase(TestCase):
+    def setUp(self):
+        # Initial state with Readable model having a title field
+        self.old_state = ProjectState()
+        self.old_state.add_model(ModelState(
+            app_label='myapp',
+            name='Readable',
+            fields=[
+                ('id', models.AutoField(primary_key=True)),
+                ('title', models.CharField(max_length=200)),
+            ],
+        ))
+
+        # New state with Book subclass having the title field
+        self.new_state = ProjectState()
+        self.new_state.add_model(ModelState(
+            app_label='myapp',
+            name='Readable',
+            fields=[
+                ('id', models.AutoField(primary_key=True)),
+            ],
+        ))
+        self.new_state.add_model(ModelState(
+            app_label='myapp',
+            name='Book',
+            fields=[
+                ('id', models.AutoField(primary_key=True)),
+                ('title', models.CharField(max_length=200)),
+            ],
+            bases=('myapp.Readable',)
+        ))
+
+    def test_migration_order(self):
+        migration = Migration('0001_initial', 'myapp')
+        migration.operations = [
+            CreateModel(
+                name='Book',
+                fields=[
+                    ('id', models.AutoField(primary_key=True)),
+                    ('title', models.CharField(max_length=200)),
+                ],
+                bases=('myapp.Readable',)
+            ),
+            RemoveField(
+                model_name='Readable',
+                name='title',
+            ),
+        ]
+
+        # Check that the migration operations are in the correct order
+        # The test should fail if the operations are in the incorrect order
+        self.assertEqual(
+            [op.__class__.__name__ for op in migration.operations],
+            ['RemoveField', 'CreateModel']
+        )

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/migrations/autodetector\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-12754
cat coverage.cover
git checkout 18759b2209ff556aed7f20d83cbf23e3d234e41c
git apply /root/pre_state.patch
