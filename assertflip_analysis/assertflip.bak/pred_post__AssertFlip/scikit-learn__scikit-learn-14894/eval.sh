#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD fdbaa58acbead5a254f2e6d597dc1ab3b947f4c6 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff fdbaa58acbead5a254f2e6d597dc1ab3b947f4c6
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/sklearn/svm/base.py b/sklearn/svm/base.py
--- a/sklearn/svm/base.py
+++ b/sklearn/svm/base.py
@@ -287,11 +287,14 @@ def _sparse_fit(self, X, y, sample_weight, solver_type, kernel,
         n_SV = self.support_vectors_.shape[0]
 
         dual_coef_indices = np.tile(np.arange(n_SV), n_class)
-        dual_coef_indptr = np.arange(0, dual_coef_indices.size + 1,
-                                     dual_coef_indices.size / n_class)
-        self.dual_coef_ = sp.csr_matrix(
-            (dual_coef_data, dual_coef_indices, dual_coef_indptr),
-            (n_class, n_SV))
+        if not n_SV:
+            self.dual_coef_ = sp.csr_matrix([])
+        else:
+            dual_coef_indptr = np.arange(0, dual_coef_indices.size + 1,
+                                         dual_coef_indices.size / n_class)
+            self.dual_coef_ = sp.csr_matrix(
+                (dual_coef_data, dual_coef_indices, dual_coef_indptr),
+                (n_class, n_SV))
 
     def predict(self, X):
         """Perform regression on samples in X.

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14894.py
new file mode 100644
index e69de29..161da6b 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-14894.py
@@ -0,0 +1,26 @@
+import pytest
+import numpy as np
+import scipy.sparse
+from sklearn.svm import SVR
+
+def test_zero_division_error_in_sparse_fit():
+    # Create a sparse matrix input that leads to an empty support_vectors_
+    x_train = np.array([[0, 1, 0, 0],
+                        [0, 0, 0, 1],
+                        [0, 0, 1, 0],
+                        [0, 0, 0, 1]])
+    y_train = np.array([0.04, 0.04, 0.10, 0.16])
+    
+    # Convert to sparse matrix
+    x_train_sparse = scipy.sparse.csr_matrix(x_train)
+    
+    # Initialize the SVR model
+    model = SVR(C=316.227766017, cache_size=200, coef0=0.0, degree=3, epsilon=0.1,
+                gamma=1.0, kernel='linear', max_iter=15000,
+                shrinking=True, tol=0.001, verbose=False)
+    
+    # Fit the model and expect no error
+    try:
+        model.fit(x_train_sparse, y_train)
+    except ZeroDivisionError:
+        pytest.fail("ZeroDivisionError was raised during sparse fit")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/svm/base\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-14894.py
cat coverage.cover
git checkout fdbaa58acbead5a254f2e6d597dc1ab3b947f4c6
git apply /root/pre_state.patch
