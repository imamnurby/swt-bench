#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD dd1615c59dc6fff633e27dbb3861f2d27e1fb976 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff dd1615c59dc6fff633e27dbb3861f2d27e1fb976
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-8548.py
new file mode 100644
index e69de29..fbae042 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-8548.py
@@ -0,0 +1,41 @@
+import pytest
+from sphinx.ext.autodoc import Documenter, Options
+from sphinx.ext.autodoc.importer import get_class_members
+
+class BaseClass:
+    """Base class with attributes."""
+    base_attr = "I am a base attribute"
+    """This is the base attribute docstring."""
+
+class DerivedClass(BaseClass):
+    """Derived class inheriting from BaseClass."""
+    derived_attr = "I am a derived attribute"
+    """This is the derived attribute docstring."""
+
+def test_autodoc_inherited_members_bug():
+    # Mock the Documenter and Options
+    class MockDocumenter(Documenter):
+        objtype = 'class'
+        def __init__(self, *args, **kwargs):
+            self.options = Options(inherited_members=True)
+            self.object = DerivedClass
+            self.objpath = ['DerivedClass']
+            self.analyzer = None
+
+    # Create a mock documenter instance
+    documenter = MockDocumenter()
+
+    # Get the class members using the buggy function
+    members = get_class_members(documenter.object, documenter.objpath, getattr, documenter.analyzer)
+
+    # Check if the base class attribute is present
+    assert 'base_attr' in members
+
+    # Check if the docstring for the base class attribute is present
+    assert members['base_attr'].docstring is not None  # Correct behavior: docstring should be present
+
+    # Check if the derived class attribute is present
+    assert 'derived_attr' in members
+
+    # Check if the docstring for the derived class attribute is present
+    assert members['derived_attr'].docstring is not None  # Correct behavior: docstring should be present

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/ext/autodoc/__init__\.py|sphinx/ext/autodoc/importer\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-8548.py
cat coverage.cover
git checkout dd1615c59dc6fff633e27dbb3861f2d27e1fb976
git apply /root/pre_state.patch
