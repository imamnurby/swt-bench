#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 6ab8c86c383dd847a1be7103ad115f174fe23ffd >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 6ab8c86c383dd847a1be7103ad115f174fe23ffd
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sklearn/tree/export.py b/sklearn/tree/export.py
--- a/sklearn/tree/export.py
+++ b/sklearn/tree/export.py
@@ -890,7 +890,8 @@ def export_text(decision_tree, feature_names=None, max_depth=10,
         value_fmt = "{}{} value: {}\n"
 
     if feature_names:
-        feature_names_ = [feature_names[i] for i in tree_.feature]
+        feature_names_ = [feature_names[i] if i != _tree.TREE_UNDEFINED
+                          else None for i in tree_.feature]
     else:
         feature_names_ = ["feature_{}".format(i) for i in tree_.feature]
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14053.py
new file mode 100644
index e69de29..c870b1f 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14053.py
@@ -0,0 +1,24 @@
+import pytest
+from sklearn.tree import DecisionTreeClassifier
+from sklearn.tree.export import export_text
+from sklearn.datasets import load_iris
+
+def test_export_text_single_feature_no_index_error():
+    # Load the iris dataset
+    X, y = load_iris(return_X_y=True)
+    # Select only one feature
+    X = X[:, 0].reshape(-1, 1)
+    
+    # Train a decision tree classifier on the single feature
+    tree = DecisionTreeClassifier()
+    tree.fit(X, y)
+    
+    # Check that no IndexError is raised when calling export_text
+    try:
+        # This should not raise an IndexError when the bug is fixed
+        tree_text = export_text(tree, feature_names=['sepal_length'])
+        assert isinstance(tree_text, str)  # Ensure the output is a string
+    except IndexError:
+        pytest.fail("IndexError was raised unexpectedly")
+
+# Note: This test will fail if the IndexError is raised, indicating the bug is present.

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/tree/export\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-14053.py
cat coverage.cover
git checkout 6ab8c86c383dd847a1be7103ad115f174fe23ffd
git apply /root/pre_state.patch
