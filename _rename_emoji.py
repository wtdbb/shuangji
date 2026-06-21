import sys
from fontTools.ttLib import TTFont

src, dst = sys.argv[1], sys.argv[2]
newname = "Apple Color Emoji"
f = TTFont(src, fontNumber=0)
name = f["name"]
# Windows platform (3,1,0x409) + Mac platform (1,0,0)
for (pid, eid, lid) in ((3, 1, 0x409), (1, 0, 0)):
    name.setName(newname, 1, pid, eid, lid)        # Family
    name.setName("Regular", 2, pid, eid, lid)      # Subfamily
    name.setName(newname, 4, pid, eid, lid)        # Full name
    name.setName("AppleColorEmoji", 6, pid, eid, lid)  # PostScript
    name.setName(newname, 16, pid, eid, lid)       # Typographic family
    name.setName("Regular", 17, pid, eid, lid)     # Typographic subfamily
f.save(dst)
print("saved:", dst)
