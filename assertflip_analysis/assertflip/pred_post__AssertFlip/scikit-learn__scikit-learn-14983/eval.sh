#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 06632c0d185128a53c57ccc73b25b6408e90bb89 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 06632c0d185128a53c57ccc73b25b6408e90bb89
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sklearn/model_selection/_split.py b/sklearn/model_selection/_split.py
--- a/sklearn/model_selection/_split.py
+++ b/sklearn/model_selection/_split.py
@@ -1163,6 +1163,9 @@ def get_n_splits(self, X=None, y=None, groups=None):
                      **self.cvargs)
         return cv.get_n_splits(X, y, groups) * self.n_repeats
 
+    def __repr__(self):
+        return _build_repr(self)
+
 
 class RepeatedKFold(_RepeatedSplits):
     """Repeated K-Fold cross validator.
@@ -2158,6 +2161,8 @@ def _build_repr(self):
         try:
             with warnings.catch_warnings(record=True) as w:
                 value = getattr(self, key, None)
+                if value is None and hasattr(self, 'cvargs'):
+                    value = self.cvargs.get(key, None)
             if len(w) and w[0].category == DeprecationWarning:
                 # if the parameter is deprecated, don't show it
                 continue

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14983.py
new file mode 100644
index e69de29..65e0362 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14983.py
@@ -0,0 +1,18 @@
+import pytest
+from sklearn.model_selection import RepeatedKFold, RepeatedStratifiedKFold
+
+def test_repeated_kfold_repr():
+    rkf = RepeatedKFold()
+    # Capture the __repr__ output
+    repr_output = repr(rkf)
+    # Assert that the output is the correct representation
+    assert repr_output == "RepeatedKFold(n_splits=5, n_repeats=10, random_state=None)", \
+        "The __repr__ output is incorrect"
+
+def test_repeated_stratified_kfold_repr():
+    rskf = RepeatedStratifiedKFold()
+    # Capture the __repr__ output
+    repr_output = repr(rskf)
+    # Assert that the output is the correct representation
+    assert repr_output == "RepeatedStratifiedKFold(n_splits=5, n_repeats=10, random_state=None)", \
+        "The __repr__ output is incorrect"

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/model_selection/_split\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-14983.py
cat coverage.cover
git checkout 06632c0d185128a53c57ccc73b25b6408e90bb89
git apply /root/pre_state.patch
