#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 67d06b18c68ee4452768f8a1e868565dd4354abf >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 67d06b18c68ee4452768f8a1e868565dd4354abf
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-10908.py
new file mode 100644
index e69de29..a7da5a7 100644
--- /dev/null
+++ b/sklearn/tests/test_coverup_scikit-learn__scikit-learn-10908.py
@@ -0,0 +1,40 @@
+import pytest
+from sklearn.feature_extraction.text import CountVectorizer
+from sklearn.exceptions import NotFittedError
+
+def test_get_feature_names_with_vocabulary_does_not_raise_not_fitted_error():
+    # Test to expose the bug where get_feature_names raises NotFittedError
+    # even when a vocabulary is provided during initialization.
+
+    # Step 1: Prepare a sample corpus
+    corpus = [
+        'This is the first document.',
+        'This is the second second document.',
+        'And the third one.',
+        'Is this the first document?',
+    ]
+
+    # Step 2: Define a vocabulary list
+    vocabulary = ['and', 'document', 'first', 'is', 'one', 'second', 'the', 'third', 'this']
+
+    # Step 3: Initialize CountVectorizer with the vocabulary
+    vectorizer = CountVectorizer(vocabulary=vocabulary)
+
+    # Step 4: Check that vocabulary_ is not set initially
+    assert not hasattr(vectorizer, "vocabulary_")
+
+    # Step 3: Call get_feature_names and ensure no exceptions are raised
+    try:
+        feature_names = vectorizer.get_feature_names()
+        assert feature_names == vocabulary
+    except NotFittedError:
+        pytest.fail("get_feature_names() raised NotFittedError unexpectedly!")
+
+    # Step 5: Call transform on the corpus to ensure the vocabulary is set
+    vectorizer.transform(corpus)
+
+    # Step 6: Re-check the vocabulary_ attribute
+    assert hasattr(vectorizer, "vocabulary_")  # This should be True after transform
+
+    # Cleanup: No state pollution expected, no cleanup needed
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sklearn/feature_extraction/text\.py)' -m pytest --no-header -rA  -p no:cacheprovider sklearn/tests/test_coverup_scikit-learn__scikit-learn-10908.py
cat coverage.cover
git checkout 67d06b18c68ee4452768f8a1e868565dd4354abf
git apply /root/pre_state.patch
