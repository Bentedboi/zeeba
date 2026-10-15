class_name Art
extends RefCounted
## All pixel art. Sprites are ASCII grids (one char = one palette colour);
## entries in MIRROR are left halves that get mirrored into full sprites.
## Tiles are generated procedurally per theme. Everything is cached.

const PAL := {
	"k": "1b1020", "K": "4a3a58", "w": "ffffff", "W": "c8c0d8", "e": "140a18",
	"g": "74d65a", "G": "3d9440", "l": "b4f27a",
	"y": "ffd34a", "Y": "c08a2a",
	"p": "c45ae8", "P": "7b2fa8", "q": "e89af5",
	"m": "ff5ad8", "M": "ffd0f4",
	"h": "6b3e26", "H": "4a2716",
	"s": "f2c29b", "S": "c98f6a",
	"o": "f08a2c", "O": "a8531a",
	"c": "bff2ff47", "C": "d9faffd9",
	"b": "5a5a6e", "B": "33334a",
	"r": "e0432c", "R": "8f2318", "n": "ff8a5c",
	"d": "8a5a3a", "D": "5a3826", "u": "b88458",
	"a": "3fd0ff", "A": "1f6fb8",
	"v": "ff3a5a",
	"z": "a0a0b8", "Z": "6a6a80",
	"f": "ff9de2",
	"t": "58e0c0", "T": "2a8a78",
	"i": "b84a3a", "I": "e2704f", "j": "6e2a2a", "J": "4c1c22",
	"L": "58e0c0",
}

# Left halves (mirrored to full width).
const MIRROR := {
	"princess": [
		"...mm...", "....k...", ".....ky.", "....kkyy",
		"...klggg", "..kggggg", "..kgwegg", "..kgeegg",
		"..kgmggk", "...kGggg", "....kkGG", "......kg",
		"....kppy", "...gkppp", "...gkppp", "...GkPpp",
		"....kppp", "...kpppp", "..kpPppp", ".kpPpppp",
		".kPPPPPP", "..kkkkkk", "....kgk.", "...kkkk.",
	],
	"dale": [
		".....CCC", "...CCccc", "..Ccchhh", "..Cchhhh",
		"..Cchsss", "..CcsKeK", "..Ccssss", "..Ccsssk",
		"..CccSss", "...CccSS", "....zzzz", "...koooW",
		"..kooooW", "..koOooW", ".okooooo", ".Okzzzzy",
		".skooooo", "..kooooo", "..kooooO", "..kooook",
		"..koook.", "..kOOOk.", "..kbbbk.", ".kbbbbk.",
	],
	"shopkeep": [
		"......kk", ".....kvv", ".....kvv", "....kkkk",
		"....kttt", "...ktttt", "..kttwww", "..ktwwww",
		"..ktwwwe", "..ktwwwe", "..kttwww", "..kttttt",
		"..kttkkk", "..kttttt", ".kTktWWW", ".ktktWWy",
		".ktktWWW", "..kktWWW", "..ktTWWW", "..ktTTTT",
		"..kttttt", ".kTttttt", ".kTTTTTT", "..kkkkkk",
	],
	"mite": [
		"........", ".....kkk", "...kkooo", "..kooOoo",
		".kooowwo", ".kooowko", ".kOooooo", ".kOOookk",
		"..kOOOOO", "...kkkkk", "...k.k.k", "..k..k..",
	],
}

# name -> [base, {row: replacement}]  (rows in the same form as the base)
const FRAMES := {
	"princess_run1": ["princess", {21: "..kkkkkk", 22: "...kgk..", 23: "..kkkk.."}],
	"princess_run2": ["princess", {22: ".....kgk", 23: ".....kkk"}],
	"princess_jump": ["princess", {11: "...g..kg", 12: "...gkppy", 13: "....kppp", 14: "....kppp", 15: "....kPpp", 22: ".....kgk", 23: "......kk"}],
	"dale_walk1": ["dale", {20: ".koook..", 21: ".kOOOk..", 22: ".kbbbk..", 23: "kbbbbk.."}],
	"dale_walk2": ["dale", {20: "....kooo", 21: "....kOOO", 22: "....kbbb", 23: "...kbbbb"}],
	"dale_hurt": ["dale", {5: "..CcsKWK", 7: "..Ccssse", 8: "..CccSse"}],
	"mite2": ["mite", {10: "....k.k.", 11: "...k..k."}],
}

const SPRITES := {
	"redrock": [
		"....kkkk....",
		"..kkrnnrk...",
		"..krnnrrrkk.",
		".krrnrrrRrk.",
		".krrrrrRRrk.",
		"krrrRrrrrRRk",
		"krRRrrrRRRRk",
		".kRRRRRRRRk.",
		"..kkkkkkkk..",
	],
	"dirt": [
		"......kk......",
		"....kkuuk.....",
		"...kuudddkk...",
		"..kudddddddk..",
		".kuddDdddDddk.",
		".kddddDdddddk.",
		"kdDddddddDdddk",
		"kkkkkkkkkkkkkk",
	],
	"sock": [
		"..kkkk....",
		"..kwwk....",
		"..kvvk....",
		"..kwwk....",
		"..kvvk....",
		"..kwwwk...",
		".kwwwwwkk.",
		"kwwwwwwwwk",
		"kvwwwvvwwk",
		".kkkkkkkk.",
	],
	"flower": [
		"...kffk...",
		"..kfMMfk..",
		".kfMyyMfk.",
		".kfMyyMfk.",
		"..kfMMfk..",
		"...kffk...",
		"....kG....",
		"..kGkG....",
		"...kGkGk..",
		"....kG....",
		"....kG....",
		"...kkkk...",
	],
	"blanket": [
		".kkkkkkkkkk.",
		"kqpqpqpqpqpk",
		"kpqpqpqpqpqk",
		"kqpqpqpqpqpk",
		"kkkkkkkkkkkk",
		"kaAaAaAaAaAk",
		"kAaAaAaAaAak",
		"kaAaAaAaAaAk",
		".kkkkkkkkkk.",
	],
	"photo": [
		"kkkkkkkkkk",
		"kwwwwwwwwk",
		"kwaaaaaawk",
		"kwaooaaawk",
		"kwoooOaawk",
		"kwooooOawk",
		"kwddddddwk",
		"kwwwwwwwwk",
		"kwwwwwwwwk",
		"kkkkkkkkkk",
	],
	"glasses": [
		"kkkkkkkkkkkk",
		"kBwBBkkBwBBk",
		"kBBBBkkBBBBk",
		".kBBk..kBBk.",
		"..kk....kk..",
	],
	"cupcake": [
		"....kv....",
		"...kwwk...",
		"..kwfwfk..",
		".kfwwwwfk.",
		".kwwfwwwk.",
		"kkkkkkkkkk",
		".kYyYyYyk.",
		".kyYyYyYk.",
		"..kYyYyk..",
		"...kkkk...",
	],
	"joke": [
		"kkkkkkkkkk",
		"kWwwwwwwWk",
		".kwkkkkwk.",
		".kwwwwwwk.",
		".kwkkkwwk.",
		".kwwwwwwk.",
		"kWwwwwwwWk",
		"kkkkkkkkkk",
	],
	"boulder": [
		"....kkkkkkkk....",
		"..kkjjjjjjjjkk..",
		".kjjIIjjjjjjjjk.",
		".kjIjjjkjjjjjJk.",
		"kjjjjjjkjjjjjjJk",
		"kjjjjjkjjjjjjjJk",
		"kjjjjjjkkjjjjjJk",
		"kjjjjjjjjkjjjjJk",
		"kJjjjjjjkjjjjjJk",
		"kjjjjjjkjjjjjJJk",
		"kJjjjjkjjjjjjJJk",
		"kJJjjjjkjjjjJJJk",
		".kJJjjjjkjjJJJk.",
		".kJJJJjjjJJJJJk.",
		"..kkJJJJJJJJkk..",
		"....kkkkkkkk....",
	],
	"beacon": [
		"..kkkk..",
		".kLLLLk.",
		".kLwLLk.",
		".kLLLLk.",
		"..kkkk..",
		"...kk...",
		"...zZ...",
		"...zZ...",
		"...zZ...",
		"...zZ...",
		"...zZ...",
		"...zZ...",
		"...zZ...",
		"..kzZk..",
		".kzzZZk.",
		"kkkkkkkk",
	],
}

const BOULDER_SWAP := {"j": "9a8a9e", "J": "6a5a70", "I": "d0c4d4"}
const MITE_SWAP := {"o": "b04a8a", "O": "6a2a5a"}
const GURBLE_SWAP := {"t": "b07ae8", "T": "6a3aa8", "v": "58e0c0"}
const BEACON_OFF := {"L": "5a5070"}

# Colours per level theme. sky: top -> horizon bands.
const THEMES := {
	"rust": {
		"top": "e2704f", "top2": "b84a3a", "body": "6e2a2a", "dark": "4c1c22", "spec": "8a3a32",
		"plat": "a0a0b8", "crystal": "58e0c0", "crystal2": "2a8a78",
		"sky": ["0e0818", "1c0e2a", "321434", "4e1c3a", "6a2440"],
		"far": "3a1430", "mid": "4e1a2c", "near": "62202c", "stars": true, "earth": true,
	},
	"cave": {
		"top": "c06ad8", "top2": "8a44a8", "body": "3a1c4a", "dark": "220e2c", "spec": "4e2a60",
		"plat": "8a7aa0", "crystal": "ff5ad8", "crystal2": "a02a8a",
		"sky": ["05030a", "0a0614", "100a1e", "160c28", "1c1030"],
		"far": "120a1e", "mid": "1a0e2a", "near": "221236", "stars": false, "earth": false,
	},
	"dusk": {
		"top": "ffb05a", "top2": "d4743a", "body": "8a3c2a", "dark": "5c2418", "spec": "a04a32",
		"plat": "c8c0d8", "crystal": "ffd34a", "crystal2": "c08a2a",
		"sky": ["1a1036", "2a2252", "34407a", "4a6aa0", "7aa4d4"],
		"far": "3a2a5a", "mid": "5a2a4a", "near": "7a3438", "stars": true, "earth": false,
	},
}

static var _cache := {}


static func tex(name: String, swap := {}) -> Texture2D:
	var key := name if swap.is_empty() else name + str(swap)
	if _cache.has(key):
		return _cache[key]
	var rows := rows_of(name)
	var w := 0
	for r in rows:
		w = maxi(w, r.length())
	var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			var hex: String = swap.get(ch, PAL.get(ch, ""))
			if hex != "":
				img.set_pixel(x, y, Color(hex))
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


static func rows_of(name: String) -> Array:
	if SPRITES.has(name):
		return SPRITES[name]
	var base := name
	var ov := {}
	if FRAMES.has(name):
		base = FRAMES[name][0]
		ov = FRAMES[name][1]
	var half: Array = MIRROR[base].duplicate()
	for i in ov:
		half[i] = ov[i]
	var out := []
	for r in half:
		var s: String = r
		out.append(s + s.reverse())
	return out


## Head-and-shoulders crop used for dialogue portraits.
static func portrait_region(name: String) -> Rect2:
	match name:
		"shopkeep": return Rect2(0, 0, 16, 14)
		_: return Rect2(0, 0, 16, 12)


# --- procedural tiles ----------------------------------------------------

static func tile(theme: String, kind: String, variant := 0) -> Texture2D:
	var key := "tile_%s_%s_%d" % [theme, kind, variant]
	if _cache.has(key):
		return _cache[key]
	var th: Dictionary = THEMES[theme]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var img: Image
	match kind:
		"plat":
			img = Image.create(16, 6, false, Image.FORMAT_RGBA8)
			var c := Color(th.plat)
			img.fill(c.darkened(0.25))
			for x in 16:
				img.set_pixel(x, 0, c.lightened(0.25))
				img.set_pixel(x, 1, c)
				img.set_pixel(x, 5, Color(PAL.k))
			for x in [2, 13]:
				img.set_pixel(x, 3, Color(PAL.k))
			for x in [0, 15]:
				for y in 6:
					img.set_pixel(x, y, Color(PAL.k))
		"spike":
			img = Image.create(16, 10, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var c1 := Color(th.crystal)
			var c2 := Color(th.crystal2)
			for i in 4:
				var h := 9 if i % 2 == 0 else 7
				for row in h:  # row 0 is the tip
					var hw := int(2.0 * row / (h - 1) + 0.3)
					for dx in range(-hw, hw + 1):
						var x := i * 4 + 2 + dx
						if x < 0 or x > 15:
							continue
						var col := c1 if dx <= 0 else c2
						if absi(dx) == hw and hw > 0:
							col = Color(PAL.k)
						img.set_pixel(x, 9 - h + row, col)
			for x in 16:
				img.set_pixel(x, 9, Color(PAL.k))
		_:
			img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
			var body := Color(th.body)
			var dark := Color(th.dark)
			var spec := Color(th.spec)
			img.fill(body)
			var strata := [4 + variant % 3, 11 + variant % 2]
			for y in strata:
				for x in 16:
					if rng.randf() < 0.7:
						img.set_pixel(x, y, dark)
			for i in 9:
				var p := Vector2i(rng.randi_range(0, 15), rng.randi_range(0, 15))
				img.set_pixel(p.x, p.y, dark if rng.randf() < 0.55 else spec)
				if rng.randf() < 0.4 and p.x < 15:
					img.set_pixel(p.x + 1, p.y, spec)
			if kind == "top":
				var top := Color(th.top)
				var top2 := Color(th.top2)
				for x in 16:
					var depth := 3 + rng.randi_range(0, 1)
					for y in depth:
						img.set_pixel(x, y, top2)
					img.set_pixel(x, 0, top)
					if rng.randf() < 0.45:
						img.set_pixel(x, 1, top)
					img.set_pixel(x, depth, dark)
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t
