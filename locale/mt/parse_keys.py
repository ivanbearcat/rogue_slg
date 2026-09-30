import re, json, io, sys

sys.stdout.reconfigure(encoding="utf-8")

src = r"E:\godot\rogue_slg\locale\keys_unique.txt"
out = r"E:\godot\rogue_slg\locale\mt\parsed_keys.json"

pat = re.compile(r"^(\d+) '(.*)'$")
keys = {}
skipped = []
raw = open(src, "rb").read()
enc = "utf-8-sig"
if raw.startswith(b"\xff\xfe") or raw.startswith(b"\xfe\xff"):
    enc = "utf-16"
text = raw.decode(enc)
for line in text.splitlines():
        if not line.strip():
            continue
        m = pat.match(line)
        if not m:
            skipped.append(line)
            continue
        keys[int(m.group(1))] = m.group(2)

n = len(keys)
missing = [i for i in range(385) if i not in keys]
print("parsed:", n, "missing:", missing, "skipped:", skipped[:5])
assert not missing and n == 385

data = [keys[i] for i in range(385)]
with open(out, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=0)
print("index0:", data[0], "| index12:", data[12], "| index66:", data[66][:40].replace("\n", "\\n"))
print("has_newlines:", [i for i, s in enumerate(data) if "\n" in s])
print("wrote", out)
