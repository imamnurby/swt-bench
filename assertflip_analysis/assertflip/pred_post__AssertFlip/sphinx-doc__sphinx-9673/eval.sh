#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 5fb51fb1467dc5eea7505402c3c5d9b378d3b441 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 5fb51fb1467dc5eea7505402c3c5d9b378d3b441
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/sphinx/ext/autodoc/typehints.py b/sphinx/ext/autodoc/typehints.py
--- a/sphinx/ext/autodoc/typehints.py
+++ b/sphinx/ext/autodoc/typehints.py
@@ -149,14 +149,14 @@ def augment_descriptions_with_types(
         elif parts[0] == 'type':
             name = ' '.join(parts[1:])
             has_type.add(name)
-        elif parts[0] == 'return':
+        elif parts[0] in ('return', 'returns'):
             has_description.add('return')
         elif parts[0] == 'rtype':
             has_type.add('return')
 
     # Add 'type' for parameters with a description but no declared type.
     for name in annotations:
-        if name == 'return':
+        if name in ('return', 'returns'):
             continue
         if name in has_description and name not in has_type:
             field = nodes.field()

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-9673.py
new file mode 100644
index e69de29..400d132 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-9673.py
@@ -0,0 +1,87 @@
+import os
+import pytest
+from sphinx.application import Sphinx
+
+@pytest.fixture
+def sphinx_app(tmpdir):
+    srcdir = tmpdir.mkdir("src")
+    confdir = tmpdir.mkdir("conf")
+    outdir = tmpdir.mkdir("out")
+    doctreedir = tmpdir.mkdir("doctree")
+
+    # Create a minimal Sphinx configuration
+    conf_file = confdir.join("conf.py")
+    conf_file.write("""
+project = 'Example Project'
+extensions = ['sphinx.ext.autodoc', 'sphinx.ext.napoleon']
+autodoc_typehints = "description"
+autodoc_typehints_description_target = "documented"
+napoleon_numpy_docstring = False
+master_doc = 'index'
+import sys
+sys.path.insert(0, '.')
+""")
+
+    # Create an index.rst file to serve as the root document
+    index_file = srcdir.join("index.rst")
+    index_file.write("""
+.. toctree::
+   example
+""")
+
+    # Create a Python module with a function that has a Google-style docstring
+    py_module_file = srcdir.join("example.py")
+    py_module_file.write("""
+def example_function(param1: int, param2: int) -> int:
+    \"\"\"
+    Description.
+
+    Parameters:
+        param1: First parameter.
+        param2: Second parameter.
+
+    Returns:
+        int: The returned value.
+    \"\"\"
+    return param1 + param2
+""")
+
+    # Create a reStructuredText file to document the module
+    example_rst_file = srcdir.join("example.rst")
+    example_rst_file.write("""
+Example Module
+==============
+
+.. automodule:: example
+    :members:
+""")
+
+    # Ensure the module path is correctly set for Sphinx to import
+    import sys
+    sys.path.insert(0, str(srcdir))
+
+    app = Sphinx(
+        srcdir=str(srcdir),
+        confdir=str(confdir),
+        outdir=str(outdir),
+        doctreedir=str(doctreedir),
+        buildername='html',
+    )
+    return app
+
+def test_missing_return_type_in_documentation(sphinx_app):
+    sphinx_app.build()
+
+    # Read the generated HTML file
+    example_html_path = os.path.join(sphinx_app.outdir, 'example.html')
+    with open(example_html_path, 'r') as f:
+        content = f.read()
+
+    # Verify that the generated documentation includes the `Returns` section
+    assert "Returns" in content or ":returns:" in content
+
+    # Check that the return type is present in the Returns section
+    assert ":rtype: int" in content
+
+    # Ensure the module was correctly imported by checking for a known string in the HTML
+    assert "Example Module" in content

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/ext/autodoc/typehints\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-9673.py
cat coverage.cover
git checkout 5fb51fb1467dc5eea7505402c3c5d9b378d3b441
git apply /root/pre_state.patch
