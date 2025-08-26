#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD fe886eee36be8022f34cfe59aa61ff1c21fe01d9 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff fe886eee36be8022f34cfe59aa61ff1c21fe01d9
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/utils/functional.py b/django/utils/functional.py
--- a/django/utils/functional.py
+++ b/django/utils/functional.py
@@ -176,6 +176,12 @@ def __mod__(self, rhs):
                 return str(self) % rhs
             return self.__cast() % rhs
 
+        def __add__(self, other):
+            return self.__cast() + other
+
+        def __radd__(self, other):
+            return other + self.__cast()
+
         def __deepcopy__(self, memo):
             # Instances of this class are effectively immutable. It's just a
             # collection of functions. So we don't need to do anything

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13794.py
new file mode 100644
index e69de29..1b432aa 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13794.py
@@ -0,0 +1,21 @@
+from django.test import SimpleTestCase
+from django.utils.translation import gettext_lazy as _
+from django.template.defaultfilters import add
+
+class AddFilterLazyStringTests(SimpleTestCase):
+    def test_add_filter_with_lazy_string(self):
+        """
+        Test the add filter with a regular string and a lazy string.
+        """
+
+        # Regular string
+        regular_string = "Hello, "
+
+        # Lazy string
+        lazy_string = _("world!")
+
+        # Use the add filter to concatenate the regular string with the lazy string
+        result = add(regular_string, lazy_string)
+
+        # Assert that the result is the concatenation of the regular string and lazy string
+        self.assertEqual(result, 'Hello, world!')

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/utils/functional\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13794
cat coverage.cover
git checkout fe886eee36be8022f34cfe59aa61ff1c21fe01d9
git apply /root/pre_state.patch
