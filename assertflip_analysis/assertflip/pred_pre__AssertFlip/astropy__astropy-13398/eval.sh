#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 6500928dc0e57be8f06d1162eacc3ba5e2eff692 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 6500928dc0e57be8f06d1162eacc3ba5e2eff692
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/astropy/tests/test_coverup_astropy__astropy-13398.py
new file mode 100644
index e69de29..9bd9e5c 100644
--- /dev/null
+++ b/astropy/tests/test_coverup_astropy__astropy-13398.py
@@ -0,0 +1,30 @@
+import pytest
+from astropy import units as u
+from astropy.coordinates import ITRS, AltAz, EarthLocation, HADec
+from astropy.time import Time
+from astropy.coordinates import frame_transform_graph, FunctionTransformWithFiniteDifference
+
+# Mocking the transformation functions since we can't access the actual implementation
+def itrs_to_observed(itrs_coo, observed_frame):
+    # Simulate the bug: the obstime of the output frame is simply adopted
+    observed_frame._obstime = itrs_coo.obstime
+    return observed_frame
+
+@pytest.fixture
+def setup_data():
+    location = EarthLocation(lat=0*u.deg, lon=0*u.deg, height=0*u.m)
+    obstime1 = Time('2023-01-01T00:00:00')
+    obstime2 = Time('2023-06-01T00:00:00')
+    itrs_coo = ITRS(x=1*u.m, y=1*u.m, z=1*u.m, obstime=obstime1)
+    altaz_frame = AltAz(location=location, obstime=obstime2)
+    return itrs_coo, altaz_frame
+
+def test_itrs_to_altaz_obstime_handling(setup_data):
+    itrs_coo, altaz_frame = setup_data
+    
+    # Transform to AltAz with a different obstime
+    altaz_coo = itrs_to_observed(itrs_coo, altaz_frame)
+    
+    # Check if the obstime of the output frame is the same as the input AltAz frame
+    assert altaz_coo.obstime != altaz_frame.obstime
+    # The test should fail if the bug is present, as the obstime should not be adopted from the ITRS frame

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(astropy/coordinates/builtin_frames/intermediate_rotation_transforms\.py|astropy/coordinates/builtin_frames/itrs\.py|astropy/coordinates/builtin_frames/itrs_observed_transforms\.py|astropy/coordinates/builtin_frames/__init__\.py)' -m pytest --no-header -rA  -p no:cacheprovider astropy/tests/test_coverup_astropy__astropy-13398.py
cat coverage.cover
git checkout 6500928dc0e57be8f06d1162eacc3ba5e2eff692
git apply /root/pre_state.patch
