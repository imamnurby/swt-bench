#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD a41edc7bf5302f2ea327943c0c48c532b12009bc >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff a41edc7bf5302f2ea327943c0c48c532b12009bc
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/xarray/core/merge.py b/xarray/core/merge.py
--- a/xarray/core/merge.py
+++ b/xarray/core/merge.py
@@ -501,7 +501,7 @@ def merge_attrs(variable_attrs, combine_attrs):
     if combine_attrs == "drop":
         return {}
     elif combine_attrs == "override":
-        return variable_attrs[0]
+        return dict(variable_attrs[0])
     elif combine_attrs == "no_conflicts":
         result = dict(variable_attrs[0])
         for attrs in variable_attrs[1:]:

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/xarray/tests/test_coverup_pydata__xarray-4629.py
new file mode 100644
index e69de29..b0e6adc 100644
--- /dev/null
+++ b/xarray/tests/test_coverup_pydata__xarray-4629.py
@@ -0,0 +1,19 @@
+import pytest
+import xarray as xr
+
+def test_merge_override_attrs_bug():
+    # Create two datasets with distinct attributes
+    xds1 = xr.Dataset(attrs={'a': 'b'})
+    xds2 = xr.Dataset(attrs={'a': 'c'})
+
+    # Merge datasets with combine_attrs='override'
+    xds3 = xr.merge([xds1, xds2], combine_attrs='override')
+
+    # Modify the attributes of the merged dataset
+    xds3.attrs['a'] = 'd'
+
+    # Assert that the original dataset's attributes have not changed
+    assert xds1.attrs['a'] == 'b', "Original dataset's attribute should not change"
+
+    # Cleanup: Reset the attribute to avoid side effects in other tests
+    xds1.attrs['a'] = 'b'

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(xarray/core/merge\.py)' -m pytest --no-header -rA  -p no:cacheprovider xarray/tests/test_coverup_pydata__xarray-4629.py
cat coverage.cover
git checkout a41edc7bf5302f2ea327943c0c48c532b12009bc
git apply /root/pre_state.patch
