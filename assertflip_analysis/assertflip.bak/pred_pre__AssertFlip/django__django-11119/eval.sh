#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d4df5e1b0b1c643fe0fc521add0236764ec8e92a >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d4df5e1b0b1c643fe0fc521add0236764ec8e92a
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11119.py
new file mode 100644
index e69de29..9aab7cb 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11119.py
@@ -0,0 +1,38 @@
+from django.test import SimpleTestCase
+from django.template import Engine
+import os
+
+class EngineRenderToStringAutoescapeTest(SimpleTestCase):
+    def setUp(self):
+        # Create a temporary template file with special characters
+        self.template_dir = os.path.join(os.path.dirname(__file__), 'templates')
+        os.makedirs(self.template_dir, exist_ok=True)
+        self.template_path = os.path.join(self.template_dir, 'test_template.html')
+        with open(self.template_path, 'w') as f:
+            f.write("{{ content }}")
+
+    def tearDown(self):
+        # Clean up the template file after the test
+        if os.path.exists(self.template_path):
+            os.remove(self.template_path)
+        try:
+            os.rmdir(self.template_dir)
+        except OSError:
+            pass  # Ignore if the directory is not empty
+
+    def test_render_to_string_autoescape_false(self):
+        """
+        Test that Engine.render_to_string() correctly does not autoescape output
+        when autoescape=False is set.
+        """
+
+        # Create an Engine with autoescape=False
+        engine = Engine(dirs=[self.template_dir], autoescape=False)
+
+        # Render the template using render_to_string
+        context = {'content': 'Test & <strong>bold</strong>'}
+        output = engine.render_to_string('test_template.html', context)
+
+        # Assert that the output is not autoescaped
+        self.assertIn('<strong>bold</strong>', output)
+        self.assertIn('Test &', output)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/template/engine\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11119
cat coverage.cover
git checkout d4df5e1b0b1c643fe0fc521add0236764ec8e92a
git apply /root/pre_state.patch
