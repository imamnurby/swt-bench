#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 06107f838c28ab6ca6bfc2cc208e15997fcb2146 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 06107f838c28ab6ca6bfc2cc208e15997fcb2146
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-9258.py
new file mode 100644
index e69de29..bf4a0fa 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-9258.py
@@ -0,0 +1,38 @@
+import pytest
+from sphinx.application import Sphinx
+from sphinx.ext.autodoc import ModuleLevelDocumenter
+from sphinx.ext.autodoc.typehints import record_typehints, merge_typehints
+from docutils.nodes import document
+from docutils import nodes
+from unittest.mock import MagicMock
+
+def test_union_type_syntax_support():
+    # Setup a Sphinx application instance with mock directories
+    app = MagicMock(spec=Sphinx)
+    app.env = MagicMock()
+    app.env.temp_data = {}
+    app.config = MagicMock()
+    app.config.autodoc_type_aliases = {}
+
+    # Define a mock function with a union type in the docstring
+    def foo(text):
+        """
+        :param text: a text
+        :type text: bytes | str
+        """
+        pass
+
+    # Create a mock document node
+    contentnode = document('', nodes.Element())
+
+    # Record type hints using the Sphinx autodoc system
+    record_typehints(app, 'function', 'foo', foo, {}, '', '')
+
+    # Attempt to merge type hints into the documentation
+    merge_typehints(app, 'py', 'function', contentnode)
+
+    # Check the annotations recorded in the Sphinx environment
+    annotations = app.env.temp_data.get('annotations', {}).get('foo', {})
+
+    # Assert that the union type is correctly represented
+    assert annotations.get('text') == 'bytes | str', "BUG: Union type 'bytes | str' is not correctly parsed"

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/domains/python\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-9258.py
cat coverage.cover
git checkout 06107f838c28ab6ca6bfc2cc208e15997fcb2146
git apply /root/pre_state.patch
