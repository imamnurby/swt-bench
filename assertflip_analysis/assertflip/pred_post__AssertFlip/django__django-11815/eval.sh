#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD e02f67ef2d03d48128e7a118bf75f0418e24e8ac >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff e02f67ef2d03d48128e7a118bf75f0418e24e8ac
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/db/migrations/serializer.py b/django/db/migrations/serializer.py
--- a/django/db/migrations/serializer.py
+++ b/django/db/migrations/serializer.py
@@ -120,9 +120,10 @@ class EnumSerializer(BaseSerializer):
     def serialize(self):
         enum_class = self.value.__class__
         module = enum_class.__module__
-        v_string, v_imports = serializer_factory(self.value.value).serialize()
-        imports = {'import %s' % module, *v_imports}
-        return "%s.%s(%s)" % (module, enum_class.__name__, v_string), imports
+        return (
+            '%s.%s[%r]' % (module, enum_class.__name__, self.value.name),
+            {'import %s' % module},
+        )
 
 
 class FloatSerializer(BaseSimpleSerializer):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11815.py
new file mode 100644
index e69de29..5efb023 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11815.py
@@ -0,0 +1,25 @@
+from django.test import SimpleTestCase
+from django.db.migrations.serializer import EnumSerializer
+from enum import Enum
+from django.utils.translation import gettext_lazy as _
+
+class Status(Enum):
+    GOOD = _('Good')  # 'Good' will be translated
+    BAD = _('Bad')    # 'Bad' will be translated
+
+    def __str__(self):
+        return self.name
+
+class MigrationTest(SimpleTestCase):
+    def test_enum_serialization_bug(self):
+        """
+        Test to expose the bug where the migration file uses the translated value
+        of an Enum object instead of its name, which causes issues when the value
+        is translated to another language.
+        """
+        # Use EnumSerializer directly to simulate the serialization process
+        serializer = EnumSerializer(Status.GOOD)
+        serialized_value, _ = serializer.serialize()
+
+        # Check if the serialized value contains the enum name instead of the translated value
+        self.assertIn("Status['GOOD']", serialized_value)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/db/migrations/serializer\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11815
cat coverage.cover
git checkout e02f67ef2d03d48128e7a118bf75f0418e24e8ac
git apply /root/pre_state.patch
