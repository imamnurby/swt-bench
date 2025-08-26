#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 19e6efa50b603af325e7f62058364f278596758f >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 19e6efa50b603af325e7f62058364f278596758f
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/views/generic/base.py b/django/views/generic/base.py
--- a/django/views/generic/base.py
+++ b/django/views/generic/base.py
@@ -148,7 +148,16 @@ def http_method_not_allowed(self, request, *args, **kwargs):
             request.path,
             extra={"status_code": 405, "request": request},
         )
-        return HttpResponseNotAllowed(self._allowed_methods())
+        response = HttpResponseNotAllowed(self._allowed_methods())
+
+        if self.view_is_async:
+
+            async def func():
+                return response
+
+            return func()
+        else:
+            return response
 
     def options(self, request, *args, **kwargs):
         """Handle responding to requests for the OPTIONS HTTP verb."""

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16136.py
new file mode 100644
index e69de29..661509f 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16136.py
@@ -0,0 +1,27 @@
+from django.test import SimpleTestCase, override_settings
+from django.urls import path
+from django.http import HttpResponse, HttpResponseNotAllowed
+from django.views import View
+
+# Define the view with only an async "post" method
+class Demo(View):
+    """This basic view supports only POST requests"""
+    async def post(self, request):
+        return HttpResponse("ok")
+
+# URL pattern to access the view
+urlpatterns = [
+    path("demo", Demo.as_view()),
+]
+
+@override_settings(ROOT_URLCONF=__name__)
+class DemoViewTests(SimpleTestCase):
+    def test_get_request_to_post_only_view(self):
+        """
+        Test that a GET request to a view with only an async "post" method
+        results in a HttpResponseNotAllowed.
+        """
+        response = self.client.get('/demo')
+        # Assert that the response is HttpResponseNotAllowed
+        self.assertEqual(response.status_code, 405)
+        self.assertIsInstance(response, HttpResponseNotAllowed)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/views/generic/base\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16136
cat coverage.cover
git checkout 19e6efa50b603af325e7f62058364f278596758f
git apply /root/pre_state.patch
