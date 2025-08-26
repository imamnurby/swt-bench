#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 82ef497a8c88f0f6e50d84520e7276bfbf65025d >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 82ef497a8c88f0f6e50d84520e7276bfbf65025d
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/sphinx/ext/viewcode.py b/sphinx/ext/viewcode.py
--- a/sphinx/ext/viewcode.py
+++ b/sphinx/ext/viewcode.py
@@ -182,6 +182,10 @@ def collect_pages(app: Sphinx) -> Generator[Tuple[str, Dict[str, Any], str], Non
     env = app.builder.env
     if not hasattr(env, '_viewcode_modules'):
         return
+    if app.builder.name == "singlehtml":
+        return
+    if app.builder.name.startswith("epub") and not env.config.viewcode_enable_epub:
+        return
     highlighter = app.builder.highlighter  # type: ignore
     urito = app.builder.get_relative_uri
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-8721.py
new file mode 100644
index e69de29..51ecbd4 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-8721.py
@@ -0,0 +1,54 @@
+import os
+import pytest
+from sphinx.application import Sphinx
+
+def test_viewcode_pages_generated_for_epub_when_disabled(tmpdir):
+    # Setup a minimal Sphinx project
+    srcdir = tmpdir.mkdir("src")
+    conf_file = srcdir.join("conf.py")
+    conf_file.write("""
+extensions = ['sphinx.ext.viewcode']
+viewcode_enable_epub = False
+""")
+    index_file = srcdir.join("index.rst")
+    index_file.write("""
+Welcome to the test documentation!
+==================================
+
+.. toctree::
+   :maxdepth: 2
+   :caption: Contents:
+
+   module1
+""")
+    module_file = srcdir.join("module1.rst")
+    module_file.write("""
+Module 1
+========
+
+.. automodule:: module1
+    :members:
+""")
+    py_module_file = srcdir.join("module1.py")
+    py_module_file.write("""
+def foo():
+    pass
+""")
+
+    # Build the Sphinx project
+    app = Sphinx(
+        srcdir=str(srcdir),
+        confdir=str(srcdir),
+        outdir=str(tmpdir.join("out")),
+        doctreedir=str(tmpdir.join("doctree")),
+        buildername='epub'
+    )
+    app.build()
+
+    # Check for the presence of viewcode pages in the EPUB output
+    epub_output_dir = tmpdir.join("out")
+    viewcode_page = epub_output_dir.join("_modules/module1.html")
+    
+    # Assert that the viewcode page is not present, which is the expected behavior
+    assert viewcode_page.exists(), "BUG: viewcode page should not be generated for EPUB when viewcode_enable_epub=False"
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/ext/viewcode\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-8721.py
cat coverage.cover
git checkout 82ef497a8c88f0f6e50d84520e7276bfbf65025d
git apply /root/pre_state.patch
