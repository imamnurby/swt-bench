#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 71db08c05197545944949d5aa76cd340e7143627 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 71db08c05197545944949d5aa76cd340e7143627
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-11445.py
new file mode 100644
index e69de29..f344b84 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-11445.py
@@ -0,0 +1,47 @@
+import os
+import pytest
+from sphinx.application import Sphinx
+
+def test_rst_prolog_with_domain_directive(tmpdir):
+    # Setup a temporary directory for the Sphinx project
+    srcdir = tmpdir.mkdir("src")
+    confdir = srcdir
+    outdir = tmpdir.mkdir("out")
+    doctreedir = tmpdir.mkdir("doctree")
+
+    # Create conf.py with rst_prolog
+    conf_py = srcdir.join("conf.py")
+    conf_py.write('rst_prolog = """\n.. |psf| replace:: Python Software Foundation\n"""\n')
+
+    # Create index.rst
+    index_rst = srcdir.join("index.rst")
+    index_rst.write("Welcome\n=======\n\n.. toctree::\n\n   mypackage\n")
+
+    # Create mypackage.rst with a domain directive in the heading
+    mypackage_rst = srcdir.join("mypackage.rst")
+    mypackage_rst.write(":mod:`mypackage2`\n=================\n\nContent\n\nSubheading\n----------\n")
+
+    # Initialize a Sphinx application
+    app = Sphinx(
+        srcdir=str(srcdir),
+        confdir=str(confdir),
+        outdir=str(outdir),
+        doctreedir=str(doctreedir),
+        buildername='html'
+    )
+
+    # Build the documentation
+    app.build()
+
+    # Check the generated HTML for the presence of the heading
+    index_html_path = os.path.join(str(outdir), "index.html")
+    with open(index_html_path, 'r') as file:
+        index_html = file.read()
+
+    # Assert that the heading with the domain directive is present
+    assert "mypackage2" in index_html  # The heading should be present when the bug is fixed
+
+    # No cleanup method is needed as Sphinx does not have a cleanup method
+
+# Note: This test assumes pytest is being used to run the test.
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/util/rst\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-11445.py
cat coverage.cover
git checkout 71db08c05197545944949d5aa76cd340e7143627
git apply /root/pre_state.patch
