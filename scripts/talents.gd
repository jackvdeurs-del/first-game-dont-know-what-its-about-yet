class_name Talents
## Every talent the player can be offered after clearing a room.
## To add one: add an entry here, then handle its "id" in Game.apply_talent().
##   once  - disappears from the pool after being picked
##   style - only offered once that fighting style is unlocked
##           (0 = Arcane Bolt, 1 = Blade Dance, 2 = Frost Nova)

const ALL := [
	{"id": "power", "name": "Arcane Power", "desc": "All attacks deal 25% more damage."},
	{"id": "haste", "name": "Quick Casting", "desc": "Attack 20% faster with every style."},
	{"id": "vitality", "name": "Vitality", "desc": "+1 max heart and heal to full."},
	{"id": "swift", "name": "Swift Feet", "desc": "Run 12% faster."},
	{"id": "double_jump", "name": "Wind Step", "desc": "Jump once more in mid-air.", "once": true},
	{"id": "extra_dash", "name": "Blink", "desc": "+1 dash before you land."},
	{"id": "regen", "name": "Second Wind", "desc": "Heal 1 heart after every room you clear.", "once": true},
	{"id": "pierce", "name": "Piercing Bolts", "desc": "Arcane bolts pass through 1 more enemy.", "style": 0},
	{"id": "multishot", "name": "Split Bolt", "desc": "Fire 1 extra arcane bolt per cast.", "style": 0},
	{"id": "big_slash", "name": "Wide Arc", "desc": "Blade Dance slashes are 30% bigger.", "style": 1},
	{"id": "nova_size", "name": "Deep Freeze", "desc": "Frost Nova reaches 30% further.", "style": 2},
]
