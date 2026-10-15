class_name Story
extends RefCounted
## All the words. Dialogue lines are "speaker|text"; an empty speaker is narration.

const SPEAKERS := {
	"zeeba": {"sprite": "princess", "swap": {}, "pitch": 1.45},
	"dale": {"sprite": "dale", "swap": {}, "pitch": 0.85},
	"blorb": {"sprite": "shopkeep", "swap": {}, "pitch": 0.65},
	"gurble": {"sprite": "shopkeep", "swap": Art.GURBLE_SWAP, "pitch": 1.15},
	"": {"sprite": "", "swap": {}, "pitch": 1.0},
}

# Side quests: nice, non-essential things to do for Dale.
const QUESTS := {
	"sock": {
		"name": "DALE'S SOCK", "kind": "item", "sprite": "sock", "reward": 5,
		"found": ["|* (You found a single sock. It smells faintly of Earth.)"],
		"give": [
			"dale|MY SOCK! My left sock!",
			"dale|I've been walking around with one cold foot this WHOLE time.",
			"zeeba|Humans have very fragile feet.",
			"|* (DALE is wearing both socks now.)",
		],
	},
	"flower": {
		"name": "STARBLOOM", "kind": "item", "sprite": "flower", "reward": 8,
		"found": ["|* (You found a glowing Mars flower.)"],
		"give": [
			"zeeba|Here. It's a starbloom. They glow when someone is kind to them.",
			"dale|For me? Nobody's ever given me a flower. Except my dentist.",
			"dale|It's glowing brighter. Is that... because of me?",
			"|* (DALE tucked the flower into his helmet.)",
		],
	},
	"view": {
		"name": "EARTHRISE", "kind": "spot", "reward": 6,
		"give": [
			"zeeba|Dale, look up. That little blue dot.",
			"dale|...Is that Earth?",
			"dale|It's so tiny. My whole life is on that dot. My cat. My mom. My sock drawer.",
			"zeeba|It'll be big again soon. I promise.",
			"dale|Thanks, Princess. I needed that.",
			"|* (DALE seems a little braver.)",
		],
	},
	"blanket": {
		"name": "SPACE BLANKET", "kind": "item", "sprite": "blanket", "reward": 10,
		"found": ["|* (You found a fuzzy space blanket.)"],
		"give": [
			"dale|*chatter chatter* I'm f-f-fine. Totally f-fine.",
			"zeeba|You're turning blue. Humans aren't supposed to be blue.",
			"dale|Oh, that's SO much better. It's like being hugged by a burrito.",
			"|* (DALE is warm and cozy.)",
		],
	},
	"joke": {
		"name": "GURBLE'S JOKE", "kind": "npc", "sprite": "joke", "reward": 7,
		"give": [
			"zeeba|Dale. Why did the astronaut break up with the moon?",
			"dale|...Why?",
			"zeeba|Because it needed SPACE!",
			"dale|...pfff. Hahaha! That's terrible! That's SO bad!",
			"dale|Thank you. I haven't laughed since the crash.",
			"|* (DALE is smiling.)",
		],
	},
	"photo": {
		"name": "CAT PHOTO", "kind": "item", "sprite": "photo", "reward": 10,
		"found": ["|* (You found a photo of a very round orange cat.)"],
		"give": [
			"dale|MR. BISCUITS! It must have fallen out of my pocket!",
			"dale|He's sixteen pounds of pure love. The vet says he's 'concerning'.",
			"zeeba|He is... magnificent. Like a small orange moon.",
			"|* (DALE is holding the photo close.)",
		],
	},
	"glasses": {
		"name": "SUNGLASSES", "kind": "item", "sprite": "glasses", "reward": 8,
		"found": ["|* (You found some sunglasses. Very cool.)"],
		"give": [
			"dale|The sun out here is SO bright. My eyes were cooking.",
			"dale|...How do I look?",
			"zeeba|Like a movie star. A sweaty, nervous movie star.",
			"|* (DALE looks cool.)",
		],
	},
	"cupcake": {
		"name": "CUPCAKE", "kind": "item", "sprite": "cupcake", "reward": 12,
		"found": ["|* (You found a cupcake. It is miraculously un-squished.)"],
		"give": [
			"zeeba|I found you a cupcake! Martian cupcakes are made of... we don't ask.",
			"dale|Wait. What day is it on Earth?",
			"dale|...It's my birthday. I totally forgot. It's my birthday!",
			"zeeba|HAPPY BIRTHDAY, DALE!!",
			"|* (DALE had the best birthday on Mars ever.)",
		],
	},
	"bench": {
		"name": "A QUIET REST", "kind": "spot", "reward": 6,
		"give": [
			"|* There's a bench overlooking the launch pads.",
			"zeeba|Let's sit for a minute. Royals need breaks too.",
			"dale|You know... this is the first time I've sat down since I crashed.",
			"dale|Mars isn't so bad. The company's good.",
			"|* (You and DALE rested a while.)",
		],
	},
}

const INTRO := [
	"|* A small escape pod crashed in the Rustfield.",
	"|* Something inside is making a whimpering noise.",
	"dale|H-hello? Is someone there? Please don't eat me.",
	"zeeba|Eat you?! I am PRINCESS ZEEBA of Mars! Royalty does not eat guests.",
	"zeeba|...Usually.",
	"dale|I'm Dale. I fix satellite dishes. I was NOT supposed to be on Mars.",
	"dale|My ship is wrecked, I only have a little water, and I think I lost a sock.",
	"zeeba|Then it's settled! I'll take you to the Royal Spaceport. A rocket there can fly you home.",
	"zeeba|Stay close, human. Mars is... a lot.",
	"dale|Okay. I'll stay VERY close.",
	"|* (DALE joined the party!)",
	"|* (Keep DALE's WATER up, and do nice things for him to earn coins.)",
]

const LEVEL_INTROS := [
	[],
	[
		"dale|It's so dark in here. And c-c-cold.",
		"zeeba|The Crimson Caverns! Only the bravest Martians come down here.",
		"dale|...Great. Love that for us.",
	],
	[
		"zeeba|Look, Dale! The Royal Spaceport! I can see the rocket from here!",
		"dale|Is the sunset... blue? Why is the sunset BLUE?",
		"zeeba|Why is yours orange? That's way weirder.",
	],
]

const ENDING := [
	"dale|This is it. The rocket home.",
	"dale|Princess... thank you. For everything. Even the dirt eating.",
	"zeeba|You were a very good guest, Dale. A little sweaty, but good.",
	"dale|If you ever visit Earth, I'll show you pizza. You'll love pizza.",
	"zeeba|I'll hold you to that, human.",
	"|* (DALE climbed aboard the rocket.)",
]

const DALE_CHATTER := [
	"dale|Are we there yet?",
	"dale|My helmet is fogging up. Is that bad? That's probably bad.",
	"dale|You're really good at jumping, Princess.",
	"dale|Do Martians have pizza? No? ...Oh no.",
	"dale|I'm not scared. My knees just do this.",
	"dale|Thanks for not leaving me behind.",
	"dale|What's your favorite rock? Mine is the one that isn't trying to eat me.",
	"dale|Back on Earth, I fix satellite dishes. Up here I mostly just... sweat.",
]

const DALE_THIRSTY := [
	"dale|I'm sooo thirsty... Is there water anywhere? Do Martians drink water?",
	"dale|My mouth is a desert. Like, a whole desert. Mars is a desert. I'm Mars.",
]

const FIRST_REDROCK := [
	"zeeba|*crunch* Mmm, red rocks! Martian royalty runs on these!",
	"dale|Did you just EAT that?",
	"zeeba|And now I'm FAST! Watch this!",
]

const FIRST_DIRT := [
	"zeeba|*munch* Fresh dirt! Good for the muscles!",
	"dale|...I'm not going to ask.",
	"|* (Punch cracked boulders with X. Each one uses up your STRENGTH.)",
]

const GURBLE_JOKE := [
	"gurble|Psst. Your human looks sad. Want a joke? It's my best one.",
	"gurble|Why did the astronaut break up with the moon?",
	"gurble|Because it needed SPACE! HAHAHA! *wheeze*",
	"|* (You learned GURBLE'S JOKE. Press C to tell it to Dale.)",
]

const GURBLE_WAIT := ["gurble|Go on, tell him! Press C! It'll kill. Not literally. Humans are fragile."]
const GURBLE_DONE := ["gurble|Did he laugh? He laughed, right? I'm a genius."]

const SHOP_HELLO := "Welcome, welcome! Blorb's Mart sells everything a fragile human needs!"
const SHOP_BYE := ["blorb|Come back soon! Bring coins! Bring the human!"]

# Shop stock: id, name, price, description.
const SHOP_ITEMS := [
	["bottle", "WATER BOTTLE", 4, "Dale drinks it when he gets thirsty. Carry up to 3."],
	["tank", "BIG WATER TANK", 12, "Dale can hold 50% more water."],
	["hat", "SUN HAT", 10, "Shady! Dale gets thirsty half as fast."],
	["bandage", "BANDAGES", 5, "Heals Dale by 1. Zeeba feels better too."],
	["rover", "MARS ROVER", 25, "Press R to ride! Fast, and Dale rides safe inside."],
]
