#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD c0a24c1dc957a3b565294213f435fefb2ec99714 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff c0a24c1dc957a3b565294213f435fefb2ec99714
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/astropy/io/fits/diff.py b/astropy/io/fits/diff.py
--- a/astropy/io/fits/diff.py
+++ b/astropy/io/fits/diff.py
@@ -1449,7 +1449,7 @@ def _diff(self):
                 arrb.dtype, np.floating
             ):
                 diffs = where_not_allclose(arra, arrb, rtol=self.rtol, atol=self.atol)
-            elif "P" in col.format:
+            elif "P" in col.format or "Q" in col.format:
                 diffs = (
                     [
                         idx

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-14539.py
new file mode 100644
index e69de29..a0b5c53 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-14539.py
@@ -0,0 +1,23 @@
+import os
+import pytest
+from astropy.io import fits
+
+def test_fitsdiff_vla_bug_exposure():
+    # Create a temporary file path
+    file_path = 'diffbug.fits'
+    
+    # Create a FITS file with a binary table HDU containing a VLA column
+    col = fits.Column(name='a', format='QD', array=[[0], [0, 0]])
+    hdu = fits.BinTableHDU.from_columns([col])
+    hdu.writeto(file_path, overwrite=True)
+
+    # Use FITSDiff to compare the file to itself
+    diff = fits.FITSDiff(file_path, file_path)
+    # Check the identical attribute to expose the bug
+    identical = diff.identical
+    # The test should fail if identical is False due to the bug
+    assert identical, "FITSDiff incorrectly reports differences in identical files"
+
+    # Cleanup: remove the temporary file
+    if os.path.exists(file_path):
+        os.remove(file_path)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/io/fits/diff\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-14539.py
cat coverage.cover
git checkout c0a24c1dc957a3b565294213f435fefb2ec99714
git apply /root/pre_state.patch
