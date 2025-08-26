#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD 6918e69600810a4664e53653d6ff0290c3c4a788 >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff 6918e69600810a4664e53653d6ff0290c3c4a788
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/sphinx/pycode/ast.py b/sphinx/pycode/ast.py
--- a/sphinx/pycode/ast.py
+++ b/sphinx/pycode/ast.py
@@ -213,10 +213,12 @@ def visit_UnaryOp(self, node: ast.UnaryOp) -> str:
         return "%s %s" % (self.visit(node.op), self.visit(node.operand))
 
     def visit_Tuple(self, node: ast.Tuple) -> str:
-        if node.elts:
-            return "(" + ", ".join(self.visit(e) for e in node.elts) + ")"
-        else:
+        if len(node.elts) == 0:
             return "()"
+        elif len(node.elts) == 1:
+            return "(%s,)" % self.visit(node.elts[0])
+        else:
+            return "(" + ", ".join(self.visit(e) for e in node.elts) + ")"
 
     if sys.version_info < (3, 8):
         # these ast nodes were deprecated in python 3.8

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-9367.py
new file mode 100644
index e69de29..eff5b41 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-9367.py
@@ -0,0 +1,25 @@
+import pytest
+import ast
+
+# Mock class to simulate the behavior of the visitor
+class MockVisitor:
+    def visit(self, node):
+        if isinstance(node, ast.Constant):
+            return str(node.value)
+        return ""
+
+def test_single_element_tuple_rendering():
+    # Create a mock AST node for a 1-element tuple
+    node = ast.Tuple(elts=[ast.Constant(value=1)], ctx=ast.Load())
+    
+    # Initialize the mock visitor
+    visitor = MockVisitor()
+    
+    # Simulate the visit_Tuple method
+    if node.elts:
+        result = "(" + ", ".join(visitor.visit(e) for e in node.elts) + ")"
+    else:
+        result = "()"
+    
+    # Assert that the output is correct when the bug is fixed
+    assert result == "(1,)"  # Correct behavior: should include the trailing comma

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/pycode/ast\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-9367.py
cat coverage.cover
git checkout 6918e69600810a4664e53653d6ff0290c3c4a788
git apply /root/pre_state.patch
