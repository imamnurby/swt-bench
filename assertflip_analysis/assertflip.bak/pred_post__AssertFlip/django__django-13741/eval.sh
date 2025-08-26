#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD d746f28949c009251a8741ba03d156964050717f >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff d746f28949c009251a8741ba03d156964050717f
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/django/contrib/auth/forms.py b/django/contrib/auth/forms.py
--- a/django/contrib/auth/forms.py
+++ b/django/contrib/auth/forms.py
@@ -56,16 +56,9 @@ class ReadOnlyPasswordHashField(forms.Field):
 
     def __init__(self, *args, **kwargs):
         kwargs.setdefault("required", False)
+        kwargs.setdefault('disabled', True)
         super().__init__(*args, **kwargs)
 
-    def bound_data(self, data, initial):
-        # Always return initial because the widget doesn't
-        # render an input field.
-        return initial
-
-    def has_changed(self, initial, data):
-        return False
-
 
 class UsernameField(forms.CharField):
     def to_python(self, value):
@@ -163,12 +156,6 @@ def __init__(self, *args, **kwargs):
         if user_permissions:
             user_permissions.queryset = user_permissions.queryset.select_related('content_type')
 
-    def clean_password(self):
-        # Regardless of what the user provides, return the initial value.
-        # This is done here, rather than on the field, because the
-        # field does not have access to the initial value
-        return self.initial.get('password')
-
 
 class AuthenticationForm(forms.Form):
     """

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-13741.py
new file mode 100644
index e69de29..a7ea68a 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-13741.py
@@ -0,0 +1,30 @@
+from django.test import TestCase
+from django.contrib.auth.models import User
+from django.contrib.auth.forms import UserChangeForm
+
+class ReadOnlyPasswordHashFieldTest(TestCase):
+    def setUp(self):
+        # Create a user instance with a known password hash
+        self.user = User.objects.create_user(username='testuser', password='testpassword')
+        self.user.set_password('testpassword')
+        self.user.save()
+
+    def test_read_only_password_hash_field_disabled(self):
+        # Initialize the form with the user instance
+        form = UserChangeForm(instance=self.user)
+
+        # Check if the 'disabled' attribute is set on the ReadOnlyPasswordHashField
+        password_field = form.fields['password']
+        self.assertTrue(password_field.widget.attrs.get('disabled', False))
+
+    def test_clean_password_method_necessity(self):
+        # Simulate form data with a tampered password field
+        form_data = {
+            'username': 'testuser',
+            'password': 'tamperedpassword',
+        }
+        form = UserChangeForm(data=form_data, instance=self.user)
+
+        # Check if the form's cleaned data returns the initial password hash
+        form.is_valid()  # Ensure form validation is called
+        self.assertNotEqual(form.cleaned_data.get('password'), form_data['password'])

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/auth/forms\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-13741
cat coverage.cover
git checkout d746f28949c009251a8741ba03d156964050717f
git apply /root/pre_state.patch
