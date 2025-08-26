#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 55b68de643b5c2d5f0a8ea7587ab3b2966021ccc >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 55b68de643b5c2d5f0a8ea7587ab3b2966021ccc
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/urls/base.py b/django/urls/base.py
--- a/django/urls/base.py
+++ b/django/urls/base.py
@@ -7,7 +7,7 @@
 from django.utils.translation import override
 
 from .exceptions import NoReverseMatch, Resolver404
-from .resolvers import get_ns_resolver, get_resolver
+from .resolvers import _get_cached_resolver, get_ns_resolver, get_resolver
 from .utils import get_callable
 
 # SCRIPT_NAME prefixes for each thread are stored here. If there's no entry for
@@ -92,7 +92,7 @@ def reverse(viewname, urlconf=None, args=None, kwargs=None, current_app=None):
 
 def clear_url_caches():
     get_callable.cache_clear()
-    get_resolver.cache_clear()
+    _get_cached_resolver.cache_clear()
     get_ns_resolver.cache_clear()
 
 
diff --git a/django/urls/resolvers.py b/django/urls/resolvers.py
--- a/django/urls/resolvers.py
+++ b/django/urls/resolvers.py
@@ -63,10 +63,14 @@ def __repr__(self):
         )
 
 
-@functools.lru_cache(maxsize=None)
 def get_resolver(urlconf=None):
     if urlconf is None:
         urlconf = settings.ROOT_URLCONF
+    return _get_cached_resolver(urlconf)
+
+
+@functools.lru_cache(maxsize=None)
+def _get_cached_resolver(urlconf=None):
     return URLResolver(RegexPattern(r'^/'), urlconf)
 
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11333.py
new file mode 100644
index e69de29..ea6bcae 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11333.py
@@ -0,0 +1,26 @@
+from django.test import TestCase
+from django.urls import get_resolver, clear_url_caches
+from django.conf import settings
+
+class URLResolverTest(TestCase):
+    def setUp(self):
+        # Set up a test URL configuration with a large number of routes
+        self.test_urlconf = 'myapp.test_urls'
+        settings.ROOT_URLCONF = self.test_urlconf
+
+    def test_multiple_urlresolver_instances(self):
+        # Clear any existing caches
+        clear_url_caches()
+
+        # Call get_resolver before handling a request
+        resolver_before = get_resolver(None)
+
+        # Simulate handling a request by setting the URL configuration
+        from django.urls.base import set_urlconf
+        set_urlconf(settings.ROOT_URLCONF)
+
+        # Call get_resolver after handling a request
+        resolver_after = get_resolver(settings.ROOT_URLCONF)
+
+        # Assert that the two URLResolver instances are the same
+        self.assertEqual(resolver_before, resolver_after)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/urls/base\.py|django/urls/resolvers\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11333
cat coverage.cover
git checkout 55b68de643b5c2d5f0a8ea7587ab3b2966021ccc
git apply /root/pre_state.patch
