#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 6ed769d58d89380ebaa1ef52b300691eefda8928 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 6ed769d58d89380ebaa1ef52b300691eefda8928
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/astropy/table/table.py b/astropy/table/table.py
--- a/astropy/table/table.py
+++ b/astropy/table/table.py
@@ -1239,13 +1239,6 @@ def _convert_data_to_col(self, data, copy=True, default_name=None, dtype=None, n
                                 f'{fully_qualified_name} '
                                 'did not return a valid mixin column')
 
-        # Structured ndarray gets viewed as a mixin unless already a valid
-        # mixin class
-        if (not isinstance(data, Column) and not data_is_mixin
-                and isinstance(data, np.ndarray) and len(data.dtype) > 1):
-            data = data.view(NdarrayMixin)
-            data_is_mixin = True
-
         # Get the final column name using precedence.  Some objects may not
         # have an info attribute. Also avoid creating info as a side effect.
         if not name:

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-13236.py
new file mode 100644
index e69de29..d06f892 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-13236.py
@@ -0,0 +1,19 @@
+import pytest
+import numpy as np
+from astropy.table import Table, Column
+
+def test_structured_array_transformation():
+    # Create a structured numpy array with multiple fields
+    structured_array = np.array([(1, 2.0), (3, 4.0)], dtype=[('a', 'i4'), ('b', 'f4')])
+    
+    # Initialize a Table object
+    table = Table()
+    
+    # Add the structured array to the table
+    table['structured'] = structured_array
+    
+    # Check the type of the column in the table
+    column_type = type(table['structured'])
+    
+    # Assert that the column type is Column, indicating it has not been transformed
+    assert column_type is Column, "BUG: the structured array should be added as a Column but is currently transformed due to the bug"

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/table/table\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-13236.py
cat coverage.cover
git checkout 6ed769d58d89380ebaa1ef52b300691eefda8928
git apply /root/pre_state.patch
