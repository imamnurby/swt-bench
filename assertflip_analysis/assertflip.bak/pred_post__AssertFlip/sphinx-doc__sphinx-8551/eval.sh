#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 57ed10c68057c96491acbd3e62254ccfaf9e3861 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 57ed10c68057c96491acbd3e62254ccfaf9e3861
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/sphinx/domains/python.py b/sphinx/domains/python.py
--- a/sphinx/domains/python.py
+++ b/sphinx/domains/python.py
@@ -272,6 +272,8 @@ def make_xref(self, rolename: str, domain: str, target: str,
         result = super().make_xref(rolename, domain, target,  # type: ignore
                                    innernode, contnode, env)
         result['refspecific'] = True
+        result['py:module'] = env.ref_context.get('py:module')
+        result['py:class'] = env.ref_context.get('py:class')
         if target.startswith(('.', '~')):
             prefix, result['reftarget'] = target[0], target[1:]
             if prefix == '.':
diff --git a/sphinx/util/docfields.py b/sphinx/util/docfields.py
--- a/sphinx/util/docfields.py
+++ b/sphinx/util/docfields.py
@@ -295,6 +295,7 @@ def transform(self, node: nodes.field_list) -> None:
                         self.directive.domain,
                         target,
                         contnode=content[0],
+                        env=self.directive.state.document.settings.env
                     )
                     if _is_single_paragraph(field_body):
                         paragraph = cast(nodes.paragraph, field_body[0])

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-8551.py
new file mode 100644
index e69de29..32f12f8 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-8551.py
@@ -0,0 +1,57 @@
+import pytest
+from sphinx.application import Sphinx
+from io import StringIO
+import os
+
+@pytest.fixture
+def sphinx_app(tmp_path):
+    srcdir = tmp_path / "src"
+    srcdir.mkdir()
+    confdir = srcdir
+    outdir = tmp_path / "out"
+    doctreedir = tmp_path / "doctree"
+    buildername = "html"
+
+    # Create a minimal conf.py file
+    (confdir / "conf.py").write_text("""
+project = 'Test Project'
+extensions = []
+""")
+
+    # Create a mock documentation structure
+    (srcdir / "index.rst").write_text("""
+    .. py:module:: mod
+
+    .. py:class:: A
+
+    .. py:module:: mod.submod
+
+    .. py:class:: A
+
+    .. py:function:: f()
+
+        :param A a: BUG: links to mod.A instead of mod.submod.A
+        :rtype: A
+    """)
+
+    app = Sphinx(
+        srcdir=str(srcdir),
+        confdir=str(confdir),
+        outdir=str(outdir),
+        doctreedir=str(doctreedir),
+        buildername=buildername,
+        warningiserror=False,
+        status=None,
+        warning=StringIO()
+    )
+    return app
+
+def test_ambiguous_class_lookup_warning(sphinx_app):
+    sphinx_app.build()
+
+    # Capture the warnings from the build process
+    warnings = sphinx_app._warning.getvalue()
+
+    # Check for the absence of warnings indicating ambiguous cross-references
+    assert "more than one target found for cross-reference 'A': mod.A, mod.submod.A" not in warnings
+    # The test should pass only when the bug is fixed and no warnings are present

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/domains/python\.py|sphinx/util/docfields\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-8551.py
cat coverage.cover
git checkout 57ed10c68057c96491acbd3e62254ccfaf9e3861
git apply /root/pre_state.patch
