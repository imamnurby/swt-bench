#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 9ed054279aeffd5b1d0642e2d24a8800389de29f >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 9ed054279aeffd5b1d0642e2d24a8800389de29f
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/sphinx/domains/python.py b/sphinx/domains/python.py
--- a/sphinx/domains/python.py
+++ b/sphinx/domains/python.py
@@ -861,7 +861,8 @@ def handle_signature(self, sig: str, signode: desc_signature) -> Tuple[str, str]
 
         typ = self.options.get('type')
         if typ:
-            signode += addnodes.desc_annotation(typ, ': ' + typ)
+            annotations = _parse_annotation(typ, self.env)
+            signode += addnodes.desc_annotation(typ, '', nodes.Text(': '), *annotations)
 
         return fullname, prefix
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-9591.py
new file mode 100644
index e69de29..c12fda6 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-9591.py
@@ -0,0 +1,99 @@
+import os
+import pytest
+from sphinx.application import Sphinx
+
+def test_property_type_annotation_cross_reference(tmpdir):
+    # Setup: Create a temporary Sphinx project with the necessary configuration
+    docs_dir = tmpdir.mkdir("docs")
+    conf_py_content = """
+project = 'sphinx-issue-9585'
+extensions = ['sphinx.ext.autodoc']
+autodoc_typehints = 'description'
+autodoc_type_aliases = {}
+"""
+    docs_dir.join("conf.py").write(conf_py_content)
+
+    # Create a Python module with the classes and properties
+    module_content = """
+from typing import Optional
+
+class Point:
+    \"\"\"
+    A class representing a point.
+
+    Attributes:
+        x: Position X.
+        y: Position Y.
+    \"\"\"
+    x: int
+    y: int
+
+class Square:
+    \"\"\"A class representing a square figure.\"\"\"
+    #: Square's start position (top-left corner).
+    start: Point
+    #: Square width.
+    width: int
+    #: Square height.
+    height: int
+
+    @property
+    def end(self) -> Point:
+        \"\"\"Square's end position (bottom-right corner).\"\"\"
+        return Point(self.start.x + self.width, self.start.y + self.height)
+
+class Rectangle:
+    \"\"\"
+    A class representing a square figure.
+
+    Attributes:
+        start: Rectangle's start position (top-left corner).
+        width: Rectangle width.
+        height: Rectangle width.
+    \"\"\"
+    start: Point
+    width: int
+    height: int
+
+    @property
+    def end(self) -> Point:
+        \"\"\"Rectangle's end position (bottom-right corner).\"\"\"
+        return Point(self.start.x + self.width, self.start.y + self.height)
+"""
+    module_path = docs_dir.join("mymodule.py")
+    module_path.write(module_content)
+
+    # Create index.rst file
+    index_rst_content = """
+.. automodule:: mymodule
+   :members:
+   :undoc-members:
+   :show-inheritance:
+"""
+    docs_dir.join("index.rst").write(index_rst_content)
+
+    # Add the module directory to sys.path to ensure it is importable
+    import sys
+    sys.path.insert(0, str(docs_dir))
+
+    # Create a Sphinx application
+    app = Sphinx(
+        srcdir=str(docs_dir),
+        confdir=str(docs_dir),
+        outdir=str(docs_dir.join("_build/html")),
+        doctreedir=str(tmpdir.join("_build/doctrees")),
+        buildername="html"
+    )
+
+    # Build the HTML documentation
+    app.build()
+
+    # Parse the generated HTML
+    index_html = docs_dir.join("_build/html/index.html").read()
+
+    # Check for the presence of cross-references in the property's type annotations
+    # The type annotation for the 'end' property should be cross-referenced
+    assert "class:`Point`" in index_html, "The type annotation for the 'end' property should be cross-referenced."
+
+    # Cleanup: Remove the module directory from sys.path
+    sys.path.pop(0)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/domains/python\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-9591.py
cat coverage.cover
git checkout 9ed054279aeffd5b1d0642e2d24a8800389de29f
git apply /root/pre_state.patch
