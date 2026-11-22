class_name KaynPaths
extends RefCounted
## Data for Kayn's three forms. The Shadow Assassin / Rhaast choice is permanent per save.
## Story lines marked (original fan-made) are NOT established lore.

enum Path { HUMAN, SHADOW_ASSASSIN, RHAAST }

const PROFILES := {
	Path.HUMAN: {
		"name": "Kayn", "tagline": "Wielder of the Darkin scythe",
		"hp_mult": 1.0, "speed_mult": 1.0, "damage_mult": 1.0, "poise_mult": 1.0, "time_mult": 1.0,
		"cd_mult": {"dashslash": 1.0, "slam": 1.0}, "lifesteal": 0.0,
		"body_color": Color(0.18, 0.12, 0.28), "blade_scale": Vector3.ONE,
		"pros": [], "cons": [], "line": "",
	},
	Path.SHADOW_ASSASSIN: {
		"name": "Shadow Assassin", "tagline": "Master of the weapon - the Darkin bends to your will",
		"hp_mult": 0.85, "speed_mult": 1.2, "damage_mult": 1.0, "poise_mult": 0.9, "time_mult": 0.8,
		"cd_mult": {"dashslash": 0.6, "slam": 1.2}, "lifesteal": 0.0,
		"body_color": Color(0.1, 0.18, 0.4), "blade_scale": Vector3(0.7, 1.0, 1.15),
		"pros": ["+20% movement speed", "+25% attack speed", "Shadow Step cooldown -40%"],
		"cons": ["-15% max health", "-10% poise", "Ground Slam cooldown +20%"],
		"line": "\"Power is a tool. I decide how it is used.\" (original fan-made line)",
	},
	Path.RHAAST: {
		"name": "Rhaast", "tagline": "Embrace the Darkin - his strength becomes yours",
		"hp_mult": 1.3, "speed_mult": 0.92, "damage_mult": 1.35, "poise_mult": 1.3, "time_mult": 1.15,
		"cd_mult": {"dashslash": 1.3, "slam": 0.6}, "lifesteal": 0.15,
		"body_color": Color(0.35, 0.05, 0.08), "blade_scale": Vector3(1.8, 1.4, 1.3),
		"pros": ["+35% damage, +30% max health, +30% poise", "Heals 15% of damage dealt", "Ground Slam cooldown -40%"],
		"cons": ["-8% movement speed", "Attacks 15% slower", "Shadow Step cooldown +30%"],
		"line": "\"Together we will end them all.\" (original fan-made line)",
	},
}

static func profile(path: int) -> Dictionary:
	return PROFILES.get(path, PROFILES[Path.HUMAN])
