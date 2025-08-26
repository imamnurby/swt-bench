#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 81a4fd973d4cfcb25d01a7b0be62cdb28f82406d >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 81a4fd973d4cfcb25d01a7b0be62cdb28f82406d
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-9711.py
new file mode 100644
index e69de29..77c3fc1 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-9711.py
@@ -0,0 +1,22 @@
+import pytest
+from unittest.mock import Mock
+from sphinx.errors import VersionRequirementError
+from sphinx.extension import verify_needs_extensions
+
+def test_verify_needs_extensions_lexicographic_bug():
+    # Setup mock Sphinx app and config
+    app = Mock()
+    config = Mock()
+    
+    # Mock extension with version '0.10.0'
+    mock_extension = Mock()
+    mock_extension.version = '0.10.0'
+    
+    # Assign the mock extension to app.extensions
+    app.extensions = {'sphinx_gallery.gen_gallery': mock_extension}
+    
+    # Set config.needs_extensions to require '0.6.0'
+    config.needs_extensions = {'sphinx_gallery.gen_gallery': '0.6.0'}
+    
+    # Expect no VersionRequirementError because '0.10.0' should satisfy '>= 0.6.0'
+    verify_needs_extensions(app, config)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/extension\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-9711.py
cat coverage.cover
git checkout 81a4fd973d4cfcb25d01a7b0be62cdb28f82406d
git apply /root/pre_state.patch
