#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git diff HEAD cab2d93076d0cca7c53fac885f927dde3e2a5fec >> /root/pre_state.patch
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git diff cab2d93076d0cca7c53fac885f927dde3e2a5fec
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git apply -v - <<'EOF_114329324912'
diff --git a/sphinx/builders/gettext.py b/sphinx/builders/gettext.py
--- a/sphinx/builders/gettext.py
+++ b/sphinx/builders/gettext.py
@@ -57,7 +57,8 @@ def add(self, msg: str, origin: Union[Element, "MsgOrigin"]) -> None:
 
     def __iter__(self) -> Generator[Message, None, None]:
         for message in self.messages:
-            positions = [(source, line) for source, line, uuid in self.metadata[message]]
+            positions = sorted(set((source, line) for source, line, uuid
+                                   in self.metadata[message]))
             uuids = [uuid for source, line, uuid in self.metadata[message]]
             yield Message(message, positions, uuids)
 

EOF_114329324912
git apply -v - <<'EOF_114329324912'
diff --git a/dev/null b/tests/test_coverup_sphinx-doc__sphinx-10466.py
new file mode 100644
index e69de29..6ea40ea 100644
--- /dev/null
+++ b/tests/test_coverup_sphinx-doc__sphinx-10466.py
@@ -0,0 +1,23 @@
+import pytest
+from sphinx.builders.gettext import Message
+
+def test_message_locations_duplicates():
+    # Simulate input with duplicate locations
+    text = "Sample text"
+    locations = [
+        ("../../manual/modeling/hair.rst", 0),
+        ("../../manual/modeling/hair.rst", 0),  # Duplicate
+        ("../../manual/modeling/hair.rst", 0),  # Duplicate
+        ("../../manual/physics/dynamic_paint/brush.rst", 0),
+        ("../../manual/physics/dynamic_paint/brush.rst", 0)  # Duplicate
+    ]
+    uuids = ["uuid1", "uuid2", "uuid3", "uuid4", "uuid5"]
+
+    # Create a Message object
+    message = Message(text, locations, uuids)
+
+    # Check for duplicates in the locations list
+    assert len(message.locations) == len(set(message.locations)), "BUG: locations list contains duplicates"
+
+    # Cleanup: No state pollution as we are not modifying any global state
+

EOF_114329324912
python3 /root/trace.py --timing --trace --count -C coverage.cover --include-pattern '/testbed/(sphinx/builders/gettext\.py)' -m tox -epy39 -v -- tests/test_coverup_sphinx-doc__sphinx-10466.py
cat coverage.cover
git checkout cab2d93076d0cca7c53fac885f927dde3e2a5fec
git apply /root/pre_state.patch
