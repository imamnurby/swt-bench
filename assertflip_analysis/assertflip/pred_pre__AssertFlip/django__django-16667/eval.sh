#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 02c356f2f3945b8075735d485c3cf48cad991011 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 02c356f2f3945b8075735d485c3cf48cad991011
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16667.py
new file mode 100644
index e69de29..5c49875 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16667.py
@@ -0,0 +1,41 @@
+from django.test import SimpleTestCase, Client, override_settings
+from django.urls import path
+from django.http import HttpResponse
+from django import forms
+from django.forms import SelectDateWidget
+
+# Define the form and view inline since we can't retrieve them
+class ReproForm(forms.Form):
+    my_date = forms.DateField(widget=SelectDateWidget())
+
+def repro_view(request):
+    form = ReproForm(request.GET)  # for ease of reproducibility
+    if form.is_valid():
+        return HttpResponse("ok")
+    else:
+        return HttpResponse("not ok")
+
+urlpatterns = [
+    path('repro/', repro_view, name='repro')
+]
+
+@override_settings(ROOT_URLCONF=__name__)
+class SelectDateWidgetTest(SimpleTestCase):
+    def setUp(self):
+        self.client = Client()
+
+    def test_overflow_error_handling(self):
+        """
+        Test that a large year value in SelectDateWidget does not crash the server.
+        """
+        try:
+            response = self.client.get('/repro/', {
+                'my_date_day': '1',
+                'my_date_month': '1',
+                'my_date_year': '1234567821345678'
+            })
+            # If no exception is raised, the test should pass because the bug is fixed
+            self.assertEqual(response.status_code, 200)
+        except OverflowError:
+            # If OverflowError is raised, the test should fail because the bug is still present
+            self.fail("OverflowError was raised due to large year value")

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/forms/widgets\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16667
cat coverage.cover
git checkout 02c356f2f3945b8075735d485c3cf48cad991011
git apply /root/pre_state.patch
