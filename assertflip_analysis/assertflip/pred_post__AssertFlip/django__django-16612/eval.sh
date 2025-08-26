#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 55bcbd8d172b689811fae17cde2f09218dd74e9c >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 55bcbd8d172b689811fae17cde2f09218dd74e9c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/contrib/admin/sites.py b/django/contrib/admin/sites.py
--- a/django/contrib/admin/sites.py
+++ b/django/contrib/admin/sites.py
@@ -453,7 +453,9 @@ def catch_all_view(self, request, url):
                 pass
             else:
                 if getattr(match.func, "should_append_slash", True):
-                    return HttpResponsePermanentRedirect("%s/" % request.path)
+                    return HttpResponsePermanentRedirect(
+                        request.get_full_path(force_append_slash=True)
+                    )
         raise Http404
 
     def _build_app_dict(self, request, label=None):

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-16612.py
new file mode 100644
index e69de29..bcddbd0 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-16612.py
@@ -0,0 +1,41 @@
+from django.test import TestCase, RequestFactory
+from django.conf import settings
+from django.http import HttpResponsePermanentRedirect, Http404
+from django.contrib.admin.sites import AdminSite
+from django.urls import resolve
+
+class CatchAllViewTest(TestCase):
+    def setUp(self):
+        # Ensure APPEND_SLASH is True for this test
+        settings.APPEND_SLASH = True
+        self.factory = RequestFactory()
+        self.admin_site = AdminSite()
+
+    def test_catch_all_view_drops_query_string(self):
+        # Simulate a request to a URL without a trailing slash and with a query string
+        request = self.factory.get('/admin/auth/foo?id=123')
+        
+        # Mock the resolve function to simulate a successful match
+        def mock_resolve(path, urlconf=None):
+            class MockMatch:
+                func = lambda: None
+                func.should_append_slash = True
+            return MockMatch()
+        
+        # Patch the resolve function in the catch_all_view method
+        original_resolve = resolve
+        try:
+            globals()['resolve'] = mock_resolve
+            # Call the catch_all_view method
+            response = self.admin_site.catch_all_view(request, 'auth/foo')
+            
+            # Check if the response is a permanent redirect
+            self.assertIsInstance(response, HttpResponsePermanentRedirect)
+            
+            # Assert that the Location header includes the query string
+            self.assertEqual(response['Location'], '/admin/auth/foo/?id=123')
+        except Http404:
+            # If Http404 is raised, the test should fail because it indicates the bug
+            self.fail("Http404 was raised, indicating the bug is present.")
+        finally:
+            globals()['resolve'] = original_resolve

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/admin/sites\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-16612
cat coverage.cover
git checkout 55bcbd8d172b689811fae17cde2f09218dd74e9c
git apply /root/pre_state.patch
