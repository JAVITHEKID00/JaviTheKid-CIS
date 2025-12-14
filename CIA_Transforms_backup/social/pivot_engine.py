import itertools, sys, json

if len(sys.argv) < 2:
    print("Usage: pivot_engine.py <username>")
    sys.exit()

base = sys.argv[1]

variantes = set()

sufijos = ["123", "01", "_pr", "_usa", "_official", "_real", "tx", "pr"]
prefijos = ["real_", "its_", "iam_", "the_", "mr_", "ms_", "el_", "la_"]

for suf in sufijos:
    variantes.add(base + suf)

for pre in prefijos:
    variantes.add(pre + base)

for combo in itertools.product([base], sufijos, prefijos):
    variantes.add(combo[2] + combo[0] + combo[1])

print(json.dumps(sorted(list(variantes)), indent=2))
