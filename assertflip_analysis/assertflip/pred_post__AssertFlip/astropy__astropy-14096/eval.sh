#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 1a4462d72eb03f30dc83a879b1dd57aac8b2c18b >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 1a4462d72eb03f30dc83a879b1dd57aac8b2c18b
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/astropy/coordinates/sky_coordinate.py b/astropy/coordinates/sky_coordinate.py
--- a/astropy/coordinates/sky_coordinate.py
+++ b/astropy/coordinates/sky_coordinate.py
@@ -894,10 +894,8 @@ def __getattr__(self, attr):
             if frame_cls is not None and self.frame.is_transformable_to(frame_cls):
                 return self.transform_to(attr)
 
-        # Fail
-        raise AttributeError(
-            f"'{self.__class__.__name__}' object has no attribute '{attr}'"
-        )
+        # Call __getattribute__; this will give correct exception.
+        return self.__getattribute__(attr)
 
     def __setattr__(self, attr, val):
         # This is to make anything available through __getattr__ immutable

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-14096.py
new file mode 100644
index e69de29..581434c 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-14096.py
@@ -0,0 +1,15 @@
+import pytest
+import astropy.coordinates as coord
+
+class CustomCoord(coord.SkyCoord):
+    @property
+    def prop(self):
+        return self.random_attr
+
+def test_custom_coord_property_access_bug():
+    c = CustomCoord('00h42m30s', '+41d12m00s', frame='icrs')
+    try:
+        _ = c.prop
+    except AttributeError as e:
+        # Correct behavior should indicate 'random_attr' is missing
+        assert "'CustomCoord' object has no attribute 'random_attr'" in str(e)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/coordinates/sky_coordinate\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-14096.py
cat coverage.cover
git checkout 1a4462d72eb03f30dc83a879b1dd57aac8b2c18b
git apply /root/pre_state.patch
