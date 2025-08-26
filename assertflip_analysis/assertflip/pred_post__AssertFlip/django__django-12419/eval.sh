#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 7fa1a93c6c8109010a6ff3f604fda83b604e0e97 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 7fa1a93c6c8109010a6ff3f604fda83b604e0e97
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/conf/global_settings.py b/django/conf/global_settings.py
--- a/django/conf/global_settings.py
+++ b/django/conf/global_settings.py
@@ -637,6 +637,6 @@ def gettext_noop(s):
 SECURE_HSTS_PRELOAD = False
 SECURE_HSTS_SECONDS = 0
 SECURE_REDIRECT_EXEMPT = []
-SECURE_REFERRER_POLICY = None
+SECURE_REFERRER_POLICY = 'same-origin'
 SECURE_SSL_HOST = None
 SECURE_SSL_REDIRECT = False

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-12419.py
new file mode 100644
index e69de29..15d91dc 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-12419.py
@@ -0,0 +1,22 @@
+from django.test import SimpleTestCase, RequestFactory
+from django.conf import settings
+from django.http import HttpResponse
+from django.middleware.security import SecurityMiddleware
+
+class SecurityMiddlewareReferrerPolicyTest(SimpleTestCase):
+    def setUp(self):
+        # Ensure SECURE_REFERRER_POLICY is not set to test the default behavior
+        settings.SECURE_REFERRER_POLICY = None
+        self.factory = RequestFactory()
+        self.middleware = SecurityMiddleware()
+
+    def test_default_referrer_policy(self):
+        # Create a mock request and response
+        request = self.factory.get('/')
+        response = HttpResponse()
+
+        # Process the response through the middleware
+        response = self.middleware.process_response(request, response)
+
+        # Assert that the Referrer-Policy header is set to "same-origin"
+        self.assertEqual(response.get('Referrer-Policy'), 'same-origin')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/conf/global_settings\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-12419
cat coverage.cover
git checkout 7fa1a93c6c8109010a6ff3f604fda83b604e0e97
git apply /root/pre_state.patch
