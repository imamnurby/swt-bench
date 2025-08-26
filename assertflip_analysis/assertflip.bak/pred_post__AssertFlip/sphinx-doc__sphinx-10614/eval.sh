#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD ac2b7599d212af7d04649959ce6926c63c3133fa >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff ac2b7599d212af7d04649959ce6926c63c3133fa
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/sphinx/ext/inheritance_diagram.py b/sphinx/ext/inheritance_diagram.py
--- a/sphinx/ext/inheritance_diagram.py
+++ b/sphinx/ext/inheritance_diagram.py
@@ -412,13 +412,16 @@ def html_visit_inheritance_diagram(self: HTML5Translator, node: inheritance_diag
     pending_xrefs = cast(Iterable[addnodes.pending_xref], node)
     for child in pending_xrefs:
         if child.get('refuri') is not None:
-            if graphviz_output_format == 'SVG':
-                urls[child['reftitle']] = "../" + child.get('refuri')
+            # Construct the name from the URI if the reference is external via intersphinx
+            if not child.get('internal', True):
+                refname = child['refuri'].rsplit('#', 1)[-1]
             else:
-                urls[child['reftitle']] = child.get('refuri')
+                refname = child['reftitle']
+
+            urls[refname] = child.get('refuri')
         elif child.get('refid') is not None:
             if graphviz_output_format == 'SVG':
-                urls[child['reftitle']] = '../' + current_filename + '#' + child.get('refid')
+                urls[child['reftitle']] = current_filename + '#' + child.get('refid')
             else:
                 urls[child['reftitle']] = '#' + child.get('refid')
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-10614.py
new file mode 100644
index e69de29..f595b08 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-10614.py
@@ -0,0 +1,70 @@
+import os
+import pytest
+from sphinx.application import Sphinx
+
+def test_svg_links_in_subdirectory_are_incorrect(tmp_path, monkeypatch):
+    # Setup: Create a temporary directory structure with sample documentation files
+    docs_source = tmp_path / "docs_source"
+    docs_build = tmp_path / "docs_build"
+    my_package = docs_source / "my_package"
+    docs_source.mkdir()
+    docs_build.mkdir()
+    my_package.mkdir()
+
+    # Create a sample index.rst in the root directory
+    index_rst = docs_source / "index.rst"
+    index_rst.write_text(
+        ".. toctree::\n"
+        "   :maxdepth: 2\n"
+        "   :caption: Contents:\n\n"
+        "   my_package/index\n"
+    )
+
+    # Create a sample index.rst in the subdirectory
+    sub_index_rst = my_package / "index.rst"
+    sub_index_rst.write_text(
+        "My Package\n"
+        "==========\n\n"
+        ".. inheritance-diagram:: my_package.my_class_1.MyClass1\n"
+        "   :parts: 1\n\n"
+        ".. autoclass:: my_package.my_class_1.MyClass1\n"
+        "   :members:\n"
+    )
+
+    # Create a sample Python file in the subdirectory
+    my_class_1_py = my_package / "my_class_1.py"
+    my_class_1_py.write_text(
+        "class MyClass1:\n"
+        "    pass\n"
+    )
+
+    # Configure Sphinx to generate documentation with SVG diagrams
+    conf_py = docs_source / "conf.py"
+    conf_py.write_text(
+        "extensions = ['sphinx.ext.autodoc', 'sphinx.ext.graphviz', 'sphinx.ext.inheritance_diagram']\n"
+        "graphviz_output_format = 'svg'\n"
+        "import os\n"
+        "import sys\n"
+        "sys.path.insert(0, os.path.abspath('.'))\n"
+    )
+
+    # Generate the documentation
+    app = Sphinx(
+        srcdir=str(docs_source),
+        confdir=str(docs_source),
+        outdir=str(docs_build),
+        doctreedir=str(docs_build / ".doctrees"),
+        buildername="html",
+    )
+    app.build()
+
+    # Check the generated SVG file for incorrect link paths
+    svg_files = list(docs_build.glob("**/inheritance-*.svg"))
+    assert svg_files, "SVG file was not generated."
+
+    # Read the SVG file and check for incorrect links
+    with open(svg_files[0], "r", encoding="utf-8") as f:
+        svg_content = f.read()
+        # Check for any incorrect link paths prefixed with '../'
+        # The test should fail if incorrect links are found
+        assert "../" not in svg_content, "The SVG links are incorrect due to the bug."

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/ext/inheritance_diagram\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-10614.py
cat coverage.cover
git checkout ac2b7599d212af7d04649959ce6926c63c3133fa
git apply /root/pre_state.patch
