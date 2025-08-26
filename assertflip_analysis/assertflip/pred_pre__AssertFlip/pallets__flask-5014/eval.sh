#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 7ee9ceb71e868944a46e1ff00b506772a53a4f1d >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 7ee9ceb71e868944a46e1ff00b506772a53a4f1d
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_pallets__flask-5014.py
new file mode 100644
index e69de29..27b1a12 100644
--- /dev/null
+++ b/tests/test_coverup_pallets__flask-5014.py
@@ -0,0 +1,7 @@
+import pytest
+from flask.blueprints import Blueprint
+
+def test_blueprint_empty_name():
+    # Attempt to create a Blueprint with an empty name
+    with pytest.raises(ValueError, match="Blueprint name must not be empty"):
+        Blueprint("", __name__)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(src/flask/blueprints\.py)' -m pytest --no-header -rA  -p no:cacheprovider tests/test_coverup_pallets__flask-5014.py
cat coverage.cover
git checkout 7ee9ceb71e868944a46e1ff00b506772a53a4f1d
git apply /root/pre_state.patch
