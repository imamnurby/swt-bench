#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD bfc4a566423e036fbdc9fb02765fd893e4860c85 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff bfc4a566423e036fbdc9fb02765fd893e4860c85
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sklearn/base.py b/sklearn/base.py
--- a/sklearn/base.py
+++ b/sklearn/base.py
@@ -48,7 +48,7 @@ def clone(estimator, safe=True):
     # XXX: not handling dictionaries
     if estimator_type in (list, tuple, set, frozenset):
         return estimator_type([clone(e, safe=safe) for e in estimator])
-    elif not hasattr(estimator, 'get_params'):
+    elif not hasattr(estimator, 'get_params') or isinstance(estimator, type):
         if not safe:
             return copy.deepcopy(estimator)
         else:

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-12585.py
new file mode 100644
index e69de29..727fd06 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-12585.py
@@ -0,0 +1,14 @@
+import pytest
+from sklearn.preprocessing import StandardScaler
+from sklearn.base import clone
+
+def test_clone_with_class_type_parameter():
+    # Attempt to clone an estimator with a class type parameter
+    try:
+        clone(StandardScaler(with_mean=StandardScaler))
+    except TypeError as e:
+        # If a TypeError is raised, the test should fail because the bug is present
+        pytest.fail("TypeError was raised, indicating the presence of the bug")
+    else:
+        # No exception should be raised, indicating the bug is fixed
+        pass

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/base\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-12585.py
cat coverage.cover
git checkout bfc4a566423e036fbdc9fb02765fd893e4860c85
git apply /root/pre_state.patch
