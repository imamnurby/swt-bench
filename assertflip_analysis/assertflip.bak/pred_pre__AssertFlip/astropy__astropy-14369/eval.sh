#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD fa4e8d1cd279acf9b24560813c8652494ccd5922 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff fa4e8d1cd279acf9b24560813c8652494ccd5922
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-14369.py
new file mode 100644
index e69de29..f0b084a 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-14369.py
@@ -0,0 +1,48 @@
+import pytest
+from astropy.table import Table
+from astropy import units as u
+from astropy.units import cds
+
+def test_incorrect_units_parsing():
+    # Enable CDS units
+    cds.enable()
+
+    # Prepare the sample MRT content
+    mrt_content = """
+Title:
+Authors:
+Table:
+===============================================================================
+Byte-by-byte Description of file: tab.txt
+--------------------------------------------------------------------------------
+   Bytes Format Units          \t\tLabel      Explanations
+--------------------------------------------------------------------------------
+   1- 10 A10    ---            \t\tID         ID
+  12- 21 F10.5  10+3J/m/s/kpc2    \tSBCONT     Cont surface brightness
+  23- 32 F10.5  10-7J/s/kpc2 \t\tSBLINE     Line surface brightness
+--------------------------------------------------------------------------------
+ID0001     70.99200   38.51040      
+ID0001     13.05120   28.19240      
+ID0001     3.83610    10.98370      
+ID0001     1.99101    6.78822       
+ID0001     1.31142    5.01932      
+    """
+
+    # Write the sample MRT content to a temporary file
+    with open('tab.txt', 'w') as f:
+        f.write(mrt_content.strip())
+
+    # Read the table using the ascii.cds format
+    dat = Table.read('tab.txt', format='ascii.cds')
+
+    # Extract the units from the SBCONT and SBLINE columns
+    sbcont_unit = dat['SBCONT'].unit.to_string(format='cds')
+    sbline_unit = dat['SBLINE'].unit.to_string(format='cds')
+
+    # Assert that the units are parsed correctly
+    assert sbcont_unit == '10+3J/m/s/kpc2'
+    assert sbline_unit == '10-7J/s/kpc2'
+
+    # Cleanup: Remove the temporary file
+    import os
+    os.remove('tab.txt')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/units/format/cds\.py|astropy/units/format/cds_parsetab\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-14369.py
cat coverage.cover
git checkout fa4e8d1cd279acf9b24560813c8652494ccd5922
git apply /root/pre_state.patch
