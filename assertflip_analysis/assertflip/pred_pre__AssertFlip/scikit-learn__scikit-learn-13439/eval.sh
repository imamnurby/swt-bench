#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a62775e99f2a5ea3d51db7160fad783f6cd8a4c5 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a62775e99f2a5ea3d51db7160fad783f6cd8a4c5
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-13439.py
new file mode 100644
index e69de29..2dd0beb 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-13439.py
@@ -0,0 +1,25 @@
+import pytest
+from sklearn import svm
+from sklearn.datasets import make_classification
+from sklearn.feature_selection import SelectKBest, f_regression
+from sklearn.pipeline import Pipeline
+
+def test_pipeline_len_bug():
+    # Generate some data to play with
+    X, y = make_classification(n_informative=5, n_redundant=0, random_state=42)
+
+    # Create a non-empty pipeline with steps
+    anova_filter = SelectKBest(f_regression, k=5)
+    clf = svm.SVC(kernel='linear')
+    pipe = Pipeline([('anova', anova_filter), ('svc', clf)])
+
+    # Test len on non-empty pipeline
+    length = len(pipe)
+    assert length == 2, "len(pipe) should return 2, but it returned: {}".format(length)
+
+    # Create a single-step pipeline
+    single_step_pipe = Pipeline([('anova', anova_filter)])
+
+    # Test len on single-step pipeline
+    length = len(single_step_pipe)
+    assert length == 1, "len(single_step_pipe) should return 1, but it returned: {}".format(length)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/pipeline\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-13439.py
cat coverage.cover
git checkout a62775e99f2a5ea3d51db7160fad783f6cd8a4c5
git apply /root/pre_state.patch
