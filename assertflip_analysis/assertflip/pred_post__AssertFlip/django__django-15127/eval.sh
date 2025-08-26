#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 9a6e2df3a8f01ea761529bec48e5a8dc0ea9575b >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 9a6e2df3a8f01ea761529bec48e5a8dc0ea9575b
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/contrib/messages/apps.py b/django/contrib/messages/apps.py
--- a/django/contrib/messages/apps.py
+++ b/django/contrib/messages/apps.py
@@ -1,7 +1,18 @@
 from django.apps import AppConfig
+from django.contrib.messages.storage import base
+from django.contrib.messages.utils import get_level_tags
+from django.test.signals import setting_changed
 from django.utils.translation import gettext_lazy as _
 
 
+def update_level_tags(setting, **kwargs):
+    if setting == 'MESSAGE_TAGS':
+        base.LEVEL_TAGS = get_level_tags()
+
+
 class MessagesConfig(AppConfig):
     name = 'django.contrib.messages'
     verbose_name = _("Messages")
+
+    def ready(self):
+        setting_changed.connect(update_level_tags)

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15127.py
new file mode 100644
index e69de29..b776a80 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15127.py
@@ -0,0 +1,14 @@
+from django.test import SimpleTestCase, override_settings
+from django.contrib.messages.storage.base import Message
+
+class MessageLevelTagOverrideTests(SimpleTestCase):
+    @override_settings(MESSAGE_TAGS={50: 'custom_tag'})
+    def test_level_tag_with_override_settings(self):
+        """
+        Test that the level_tag property updates with @override_settings.
+        """
+        # Create a Message instance with a level that should map to the overridden tag
+        message = Message(level=50, message="Test message")
+
+        # Assert that the level_tag is 'custom_tag', indicating the bug is fixed
+        self.assertEqual(message.level_tag, 'custom_tag')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/messages/apps\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15127
cat coverage.cover
git checkout 9a6e2df3a8f01ea761529bec48e5a8dc0ea9575b
git apply /root/pre_state.patch
