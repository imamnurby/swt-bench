#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD af8a6e592a1a15d92d77011856d5aa0ec4db4c6c >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff af8a6e592a1a15d92d77011856d5aa0ec4db4c6c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-15100.py
new file mode 100644
index e69de29..ecbca53 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-15100.py
@@ -0,0 +1,13 @@
+import pytest
+from sklearn.feature_extraction.text import strip_accents_unicode
+
+def test_strip_accents_unicode_bug():
+    # Test strings
+    s1 = chr(241)  # "ñ" as a single code point
+    s2 = chr(110) + chr(771)  # "n" followed by a combining tilde
+
+    # Expected behavior: both should be stripped to "n"
+    assert strip_accents_unicode(s1) == "n"
+    
+    # Correct the assertion to expose the bug
+    assert strip_accents_unicode(s2) == "n"

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/feature_extraction/text\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-15100.py
cat coverage.cover
git checkout af8a6e592a1a15d92d77011856d5aa0ec4db4c6c
git apply /root/pre_state.patch
