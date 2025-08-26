#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 07983a5a8704ad91ae855218ecbda1c8598200ca >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 07983a5a8704ad91ae855218ecbda1c8598200ca
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-8593.py
new file mode 100644
index e69de29..17df6ef 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-8593.py
@@ -0,0 +1,52 @@
+import os
+import pytest
+from sphinx.application import Sphinx
+
+@pytest.fixture
+def sphinx_app(tmpdir):
+    # Create a temporary directory for the Sphinx project
+    srcdir = tmpdir.mkdir("src")
+    confdir = srcdir
+    outdir = tmpdir.mkdir("out")
+    doctreedir = tmpdir.mkdir("doctree")
+
+    # Create conf.py
+    conf_content = """
+extensions = ['sphinx.ext.autodoc']
+"""
+    confdir.join("conf.py").write(conf_content)
+
+    # Create example.py with a variable using :meta public:
+    example_content = """
+_foo = None  #: :meta public:
+"""
+    srcdir.join("example.py").write(example_content)
+
+    # Create index.rst to include the module
+    index_content = """
+.. automodule:: example
+   :members:
+"""
+    srcdir.join("index.rst").write(index_content)
+
+    # Initialize the Sphinx application
+    app = Sphinx(
+        srcdir=str(srcdir),
+        confdir=str(confdir),
+        outdir=str(outdir),
+        doctreedir=str(doctreedir),
+        buildername='html'
+    )
+    return app, outdir
+
+def test_meta_public_variable_not_documented(sphinx_app):
+    app, outdir = sphinx_app
+
+    # Build the documentation
+    app.build()
+
+    # Check the output HTML file for the presence of _foo
+    index_html = outdir.join("index.html").read()
+
+    # Assert that _foo is documented
+    assert "_foo" in index_html

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/ext/autodoc/__init__\.py|sphinx/ext/autodoc/importer\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-8593.py
cat coverage.cover
git checkout 07983a5a8704ad91ae855218ecbda1c8598200ca
git apply /root/pre_state.patch
