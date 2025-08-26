#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 21698c14461d27933864d73e6fba568a154e83b3 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 21698c14461d27933864d73e6fba568a154e83b3
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-8621.py
new file mode 100644
index e69de29..b24168b 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-8621.py
@@ -0,0 +1,41 @@
+import pytest
+from docutils import nodes
+from docutils.parsers.rst import Parser
+from docutils.utils import new_document
+from docutils.frontend import OptionParser
+from docutils.parsers.rst import roles
+from sphinx.roles import generic_docroles
+
+def test_kbd_role_with_separators():
+    # Setup a minimal document
+    settings = OptionParser(components=(Parser,)).get_default_values()
+    document = new_document('test', settings)
+
+    # Register the kbd role using the generic_docroles from sphinx
+    roles.register_generic_role('kbd', generic_docroles['kbd'])
+
+    # Define test cases for standalone and compound keystrokes
+    test_cases = [
+        (':kbd:`-`', '<kbd class="kbd docutils literal notranslate">-</kbd>'),
+        (':kbd:`+`', '<kbd class="kbd docutils literal notranslate">+</kbd>'),
+        (':kbd:`Shift-+`', '<kbd class="kbd docutils literal notranslate">Shift-+</kbd>')
+    ]
+
+    for input_text, expected_html in test_cases:
+        # Parse the input text
+        document = new_document('test', settings)
+        parser = Parser()
+        parser.parse(input_text, document)
+
+        # Get the first node which should be a literal node
+        node = document[0][0]
+
+        # Check if the node is a literal node
+        assert isinstance(node, nodes.literal)
+
+        # Get the children of the node which contains the HTML
+        result_html = ''.join(child.astext() for child in node.children)
+
+        # Assert that the generated HTML matches the expected correct output
+        assert result_html == expected_html, f"Expected HTML structure {expected_html}, got {result_html}"
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/builders/html/transforms\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-8621.py
cat coverage.cover
git checkout 21698c14461d27933864d73e6fba568a154e83b3
git apply /root/pre_state.patch
