#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD b19bce971e82f2497d67fdacdeca8db08ae0ba56 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff b19bce971e82f2497d67fdacdeca8db08ae0ba56
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/sphinx/ext/autodoc/__init__.py b/sphinx/ext/autodoc/__init__.py
--- a/sphinx/ext/autodoc/__init__.py
+++ b/sphinx/ext/autodoc/__init__.py
@@ -1074,7 +1074,7 @@ def get_module_members(self) -> Dict[str, ObjectMember]:
     def get_object_members(self, want_all: bool) -> Tuple[bool, ObjectMembers]:
         members = self.get_module_members()
         if want_all:
-            if not self.__all__:
+            if self.__all__ is None:
                 # for implicit module members, check __module__ to avoid
                 # documenting imported objects
                 return True, list(members.values())

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-8595.py
new file mode 100644
index e69de29..1ae6518 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-8595.py
@@ -0,0 +1,76 @@
+import os
+import pytest
+from sphinx.application import Sphinx
+
+@pytest.fixture
+def setup_sphinx_environment(tmp_path):
+    # Create a temporary directory for the Sphinx project
+    docs_dir = tmp_path / "docs"
+    docs_dir.mkdir()
+
+    # Create a conf.py file
+    conf_py = docs_dir / "conf.py"
+    conf_py.write_text("""
+project = 'Example Project'
+extensions = ['sphinx.ext.autodoc']
+    """)
+
+    # Create an example.py module with an empty __all__
+    example_py = docs_dir / "example.py"
+    example_py.write_text("""
+__all__ = []
+
+def foo():
+    \"\"\"docstring\"\"\"
+
+def bar():
+    \"\"\"docstring\"\"\"
+
+def baz():
+    \"\"\"docstring\"\"\"
+    """)
+
+    # Create an index.rst file
+    index_rst = docs_dir / "index.rst"
+    index_rst.write_text("""
+.. automodule:: example
+   :members:
+    """)
+
+    return docs_dir
+
+def test_empty_all_attribute_exposes_bug(setup_sphinx_environment):
+    docs_dir = setup_sphinx_environment
+
+    # Run the Sphinx build process
+    app = Sphinx(
+        srcdir=str(docs_dir),
+        confdir=str(docs_dir),
+        outdir=str(docs_dir / "_build"),
+        doctreedir=str(docs_dir / "_doctrees"),
+        buildername="html",
+    )
+    app.build()
+
+    # Read the output HTML file
+    output_html = docs_dir / "_build" / "index.html"
+    output_content = output_html.read_text()
+
+    # Assert that no members are documented, which is the correct behavior
+    # We expect no members to be documented since __all__ is empty
+    assert not any(member in output_content for member in ["foo", "bar", "baz"])
+
+    # Cleanup: Remove the generated files to avoid state pollution
+    for item in docs_dir.iterdir():
+        if item.is_dir():
+            for sub_item in item.iterdir():
+                if sub_item.is_dir():
+                    for sub_sub_item in sub_item.iterdir():
+                        sub_sub_item.unlink()
+                    sub_item.rmdir()
+                else:
+                    sub_item.unlink()
+            item.rmdir()
+        else:
+            item.unlink()
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/ext/autodoc/__init__\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-8595.py
cat coverage.cover
git checkout b19bce971e82f2497d67fdacdeca8db08ae0ba56
git apply /root/pre_state.patch
