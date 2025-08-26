#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD f35d2a6cc726f97d0e859ca7a0e1729f7da8a6c8 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff f35d2a6cc726f97d0e859ca7a0e1729f7da8a6c8
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-10673.py
new file mode 100644
index e69de29..452003a 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-10673.py
@@ -0,0 +1,63 @@
+import os
+import pytest
+from sphinx.application import Sphinx
+from io import StringIO
+
+@pytest.fixture
+def sphinx_app(tmpdir):
+    # Set up a temporary directory for the Sphinx project
+    srcdir = tmpdir.mkdir("src")
+    confdir = srcdir
+    outdir = tmpdir.mkdir("out")
+    doctreedir = tmpdir.mkdir("doctree")
+
+    # Create a minimal conf.py with necessary configurations
+    conf_py = confdir.join("conf.py")
+    conf_py.write("""
+project = 'Test Project'
+master_doc = 'index'
+html_use_index = True
+html_use_modindex = True
+html_use_search = True
+""")
+
+    # Create an index.rst with the problematic toctree directive
+    index_rst = confdir.join("index.rst")
+    index_rst.write("""
+.. toctree::
+   :maxdepth: 1
+   :caption: Indices and tables
+
+   genindex 
+   modindex
+   search
+""")
+
+    # Initialize the Sphinx application with StringIO for capturing warnings
+    warning_stream = StringIO()
+    app = Sphinx(
+        srcdir=str(confdir),
+        confdir=str(confdir),
+        outdir=str(outdir),
+        doctreedir=str(doctreedir),
+        buildername='html',
+        warning=warning_stream
+    )
+    return app, warning_stream
+
+def test_toctree_nonexisting_documents(sphinx_app):
+    app, warning_stream = sphinx_app
+
+    # Run the Sphinx build process
+    app.build()
+
+    # Get the warnings from the StringIO stream
+    warnings = warning_stream.getvalue()
+
+    # Check for warnings about non-existing documents
+    assert "toctree contains reference to nonexisting document 'genindex'" not in warnings, \
+        "The toctree should not contain reference to nonexisting document 'genindex'"
+    assert "toctree contains reference to nonexisting document 'modindex'" not in warnings, \
+        "The toctree should not contain reference to nonexisting document 'modindex'"
+    assert "toctree contains reference to nonexisting document 'search'" not in warnings, \
+        "The toctree should not contain reference to nonexisting document 'search'"

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/environment/adapters/toctree\.py|sphinx/directives/other\.py|sphinx/environment/collectors/toctree\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-10673.py
cat coverage.cover
git checkout f35d2a6cc726f97d0e859ca7a0e1729f7da8a6c8
git apply /root/pre_state.patch
