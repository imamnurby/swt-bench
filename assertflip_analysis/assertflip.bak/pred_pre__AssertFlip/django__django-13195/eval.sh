#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 156a2138db20abc89933121e4ff2ee2ce56a173a >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 156a2138db20abc89933121e4ff2ee2ce56a173a
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13195.py
new file mode 100644
index e69de29..59fa750 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13195.py
@@ -0,0 +1,18 @@
+from django.test import SimpleTestCase
+from django.http import HttpResponse
+
+class DeleteCookieSameSiteTest(SimpleTestCase):
+    def test_delete_cookie_preserves_samesite(self):
+        response = HttpResponse()
+        
+        # Set a cookie with SameSite attribute
+        response.set_cookie('test_cookie', 'value', samesite='Lax')
+        
+        # Delete the cookie
+        response.delete_cookie('test_cookie')
+        
+        # Get the Set-Cookie header
+        set_cookie_header = response.cookies['test_cookie'].output()
+        
+        # Assert that the SameSite attribute is not preserved
+        self.assertNotIn('SameSite=Lax', set_cookie_header)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/messages/storage/cookie\.py|django/http/response\.py|django/contrib/sessions/middleware\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13195
cat coverage.cover
git checkout 156a2138db20abc89933121e4ff2ee2ce56a173a
git apply /root/pre_state.patch
