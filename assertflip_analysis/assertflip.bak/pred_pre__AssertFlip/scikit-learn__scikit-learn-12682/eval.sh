#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d360ffa7c5896a91ae498b3fb9cf464464ce8f34 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d360ffa7c5896a91ae498b3fb9cf464464ce8f34
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-12682.py
new file mode 100644
index e69de29..2c9e005 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-12682.py
@@ -0,0 +1,25 @@
+import pytest
+import numpy as np
+from sklearn.decomposition import SparseCoder
+from sklearn.linear_model import Lasso
+from sklearn.exceptions import ConvergenceWarning
+import warnings
+
+def test_sparse_coder_lasso_cd_max_iter_bug():
+    # Create a dataset and dictionary that are computationally intensive
+    X = np.random.rand(100, 50)
+    dictionary = np.random.rand(50, 50)
+    
+    # Initialize SparseCoder with lasso_cd algorithm
+    coder = SparseCoder(dictionary=dictionary, transform_algorithm='lasso_cd', transform_alpha=0.1)
+    
+    # Capture warnings
+    with warnings.catch_warnings(record=True) as w:
+        warnings.simplefilter("always")
+        coder.transform(X)
+        
+        # Check if a ConvergenceWarning was raised
+        convergence_warnings = [warning for warning in w if issubclass(warning.category, ConvergenceWarning)]
+        
+        # The test should fail if a warning is raised, indicating the bug is present
+        assert len(convergence_warnings) == 0  # The test passes only if no warning is raised, indicating the bug is fixed

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/decomposition/dict_learning\.py|examples/decomposition/plot_sparse_coding\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-12682.py
cat coverage.cover
git checkout d360ffa7c5896a91ae498b3fb9cf464464ce8f34
git apply /root/pre_state.patch
