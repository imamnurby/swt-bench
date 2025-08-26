#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD e8fcdaad5c428878d0a5d6ba820d957013f75595 >> /root/pre_state.patch
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff e8fcdaad5c428878d0a5d6ba820d957013f75595
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_django__django-12155.py
new file mode 100644
index e69de29..62ae520 100644
--- /dev/null
+++ b/tests/test_coverup_django__django-12155.py
@@ -0,0 +1,21 @@
+from django.test import SimpleTestCase
+
+class TrimDocstringTest(SimpleTestCase):
+    def test_trim_docstring_with_non_empty_first_line(self):
+        """
+        Test trim_docstring with a docstring where the first line is not empty.
+        """
+        docstring = """This is a test docstring.
+        It has multiple lines.
+        """
+        expected_output = "This is a test docstring.\nIt has multiple lines."
+
+        # Call the trim_docstring function
+        from django.contrib.admindocs.utils import trim_docstring
+        output = trim_docstring(docstring)
+
+        # Assert that the output is a non-empty string
+        self.assertTrue(output)
+        
+        # The output should match the expected trimmed version of the docstring
+        self.assertEqual(output, expected_output)

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(django/contrib/admindocs/views\.py|django/contrib/admindocs/utils\.py)' ./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 test_coverup_django__django-12155
cat coverage.cover
git checkout e8fcdaad5c428878d0a5d6ba820d957013f75595
git apply /root/pre_state.patch
