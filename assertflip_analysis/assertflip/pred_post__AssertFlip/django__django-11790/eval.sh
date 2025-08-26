#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD b1d6b35e146aea83b171c1b921178bbaae2795ed >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff b1d6b35e146aea83b171c1b921178bbaae2795ed
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/contrib/auth/forms.py b/django/contrib/auth/forms.py
--- a/django/contrib/auth/forms.py
+++ b/django/contrib/auth/forms.py
@@ -191,7 +191,9 @@ def __init__(self, request=None, *args, **kwargs):
 
         # Set the max length and label for the "username" field.
         self.username_field = UserModel._meta.get_field(UserModel.USERNAME_FIELD)
-        self.fields['username'].max_length = self.username_field.max_length or 254
+        username_max_length = self.username_field.max_length or 254
+        self.fields['username'].max_length = username_max_length
+        self.fields['username'].widget.attrs['maxlength'] = username_max_length
         if self.fields['username'].label is None:
             self.fields['username'].label = capfirst(self.username_field.verbose_name)
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-11790.py
new file mode 100644
index e69de29..7ca399b 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-11790.py
@@ -0,0 +1,17 @@
+from django.test import SimpleTestCase
+from django.contrib.auth.forms import AuthenticationForm
+
+class AuthenticationFormMaxLengthTest(SimpleTestCase):
+    def test_username_field_maxlength_presence(self):
+        """
+        Test that the maxlength attribute is present in the username field's HTML.
+        This confirms the expected behavior where maxlength is set.
+        """
+        form = AuthenticationForm()
+        form_html = form.as_p()
+        
+        # Extract the username field's HTML
+        username_field_html = form.fields['username'].widget.render('username', '')
+        
+        # Check that maxlength is present in the username field's HTML
+        self.assertIn('maxlength', username_field_html)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/auth/forms\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-11790
cat coverage.cover
git checkout b1d6b35e146aea83b171c1b921178bbaae2795ed
git apply /root/pre_state.patch
