#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 232dbe41c5250eb7d559d40438c4743483e95f15 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 232dbe41c5250eb7d559d40438c4743483e95f15
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/sphinx/ext/autodoc/mock.py b/sphinx/ext/autodoc/mock.py
--- a/sphinx/ext/autodoc/mock.py
+++ b/sphinx/ext/autodoc/mock.py
@@ -26,6 +26,7 @@ class _MockObject:
     """Used by autodoc_mock_imports."""
 
     __display_name__ = '_MockObject'
+    __name__ = ''
     __sphinx_mock__ = True
     __sphinx_decorator_args__: Tuple[Any, ...] = ()
 
@@ -40,7 +41,7 @@ def __new__(cls, *args: Any, **kwargs: Any) -> Any:
         return super().__new__(cls)
 
     def __init__(self, *args: Any, **kwargs: Any) -> None:
-        self.__qualname__ = ''
+        self.__qualname__ = self.__name__
 
     def __len__(self) -> int:
         return 0
@@ -73,6 +74,7 @@ def _make_subclass(name: str, module: str, superclass: Any = _MockObject,
                    attributes: Any = None, decorator_args: Tuple = ()) -> Any:
     attrs = {'__module__': module,
              '__display_name__': module + '.' + name,
+             '__name__': name,
              '__sphinx_decorator_args__': decorator_args}
     attrs.update(attributes or {})
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-9658.py
new file mode 100644
index e69de29..956d557 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-9658.py
@@ -0,0 +1,50 @@
+import pytest
+from unittest import mock
+from sphinx.ext.autodoc import ClassDocumenter
+import sys
+
+def test_incorrect_bases_section(monkeypatch):
+    # Mock the torch.nn.Module class
+    mock_module = mock.MagicMock()
+    mock_module.__name__ = 'torch.nn'
+    mock_module.Module = mock.MagicMock()
+    mock_module.Module.__name__ = 'Module'
+    mock_module.Module.__module__ = 'torch.nn'
+    mock_module.Module.__bases__ = (mock_module,)
+    sys.modules['torch'] = mock_module
+    sys.modules['torch.nn'] = mock_module
+
+    # Create a mock class that inherits from mocked torch.nn.Module
+    class MockedDeepKernel(mock_module.Module):
+        pass
+
+    # Mock the Sphinx environment and configuration
+    mock_env = mock.MagicMock()
+    mock_directive = mock.MagicMock()
+    mock_directive.env = mock_env
+    mock_directive.genopt = mock.MagicMock()
+    mock_directive.state = mock.MagicMock()
+    mock_directive.state.document = mock.MagicMock()
+    mock_directive.state.document.settings = mock.MagicMock()
+    mock_directive.state.document.settings.tab_width = 4
+
+    # Create a ClassDocumenter instance
+    documenter = ClassDocumenter(mock_directive, 'MockedDeepKernel')
+    documenter.object = MockedDeepKernel
+    documenter.objpath = ['MockedDeepKernel']
+    documenter.modname = 'mocked_module'
+    documenter.fullname = 'mocked_module.MockedDeepKernel'
+    documenter.options = mock.MagicMock()
+    documenter.options.show_inheritance = True
+    documenter.doc_as_attr = False
+
+    # Mock the add_line method to capture output
+    captured_lines = []
+    monkeypatch.setattr(documenter, 'add_line', lambda line, source, *lineno: captured_lines.append(line))
+
+    # Call the method to add the directive header
+    documenter.add_directive_header('')
+
+    # Check for the presence of the correct "Bases" section
+    # We expect the correct behavior to show "Bases: torch.nn.Module"
+    assert any('Bases: torch.nn.Module' in line for line in captured_lines)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/ext/autodoc/mock\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-9658.py
cat coverage.cover
git checkout 232dbe41c5250eb7d559d40438c4743483e95f15
git apply /root/pre_state.patch
