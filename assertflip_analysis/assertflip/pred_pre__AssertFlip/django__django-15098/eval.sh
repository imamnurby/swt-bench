#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 2c7846d992ca512d36a73f518205015c88ed088c >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 2c7846d992ca512d36a73f518205015c88ed088c
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-15098.py
new file mode 100644
index e69de29..6dfba50 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-15098.py
@@ -0,0 +1,45 @@
+from django.test import TestCase, Client
+from django.conf import settings
+from django.urls import path
+from django.conf.urls.i18n import i18n_patterns
+from django.http import HttpResponse
+from django.test.utils import override_settings
+
+def bangiah(request):
+    return HttpResponse('U!')
+
+urlpatterns = [
+    path('', lambda request: HttpResponse('Root')),
+]
+
+urlpatterns += i18n_patterns(
+    path('', bangiah),
+)
+
+@override_settings(
+    LANGUAGES=[
+        ('en-us', "English"),
+        ('en-latn-us', "Latin English"),
+        ('en-Latn-US', "BCP 47 case format"),
+    ],
+    LANGUAGE_CODE='en-us',
+    USE_I18N=True,
+    MIDDLEWARE=[
+        'django.middleware.locale.LocaleMiddleware',
+    ]
+)
+class InternationalisationTestCase(TestCase):
+    def setUp(self):
+        self.client = Client()
+
+    def test_en_us_locale(self):
+        response = self.client.get('/en-us/')
+        self.assertEqual(response.status_code, 200)
+
+    def test_en_latn_us_locale(self):
+        response = self.client.get('/en-latn-us/')
+        self.assertEqual(response.status_code, 200)
+
+    def test_en_Latn_US_locale(self):
+        response = self.client.get('/en-Latn-US/')
+        self.assertEqual(response.status_code, 200)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/utils/translation/trans_real\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-15098
cat coverage.cover
git checkout 2c7846d992ca512d36a73f518205015c88ed088c
git apply /root/pre_state.patch
