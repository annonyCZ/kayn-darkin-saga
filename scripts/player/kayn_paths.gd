class_name KaynPaths
extends RefCounted
## Data for Kayn's three forms. The Shadow Assassin / Rhaast choice is permanent per save.
## Story lines marked (original fan-made) are NOT established lore.

enum Path { HUMAN, SHADOW_ASSASSIN, RHAAST }

const PROFILES := {
	Path.HUMAN: {
		"name": "Kayn", "tagline": "Nositel darkinské kosy",
		"hp_mult": 1.0, "speed_mult": 1.0, "damage_mult": 1.0, "poise_mult": 1.0, "time_mult": 1.0,
		"cd_mult": {"dashslash": 1.0, "slam": 1.0}, "lifesteal": 0.0,
		"body_color": Color(0.18, 0.12, 0.28), "blade_scale": Vector3.ONE,
		"pros": [], "cons": [], "line": "",
	},
	Path.SHADOW_ASSASSIN: {
		"name": "Stínový zabiják", "tagline": "Pán zbraně - Darkin se podřizuje tvé vůli",
		"hp_mult": 0.85, "speed_mult": 1.2, "damage_mult": 1.0, "poise_mult": 0.9, "time_mult": 0.8,
		"cd_mult": {"dashslash": 0.6, "slam": 1.2}, "lifesteal": 0.0,
		"body_color": Color(0.1, 0.18, 0.4), "blade_scale": Vector3(0.7, 1.0, 1.15),
		"pros": ["+20 % rychlost pohybu", "+25 % rychlost útoků", "Krok stínu: obnova -40 %"],
		"cons": ["-15 % maximální zdraví", "-10 % odolnost proti omráčení", "Úder do země: obnova +20 %"],
		"line": "„Síla je nástroj. Já rozhoduji, jak se použije.“ (původní fanouškovská replika)",
	},
	Path.RHAAST: {
		"name": "Rhaast", "tagline": "Přijmi Darkina - jeho síla se stane tvou",
		"hp_mult": 1.3, "speed_mult": 0.92, "damage_mult": 1.35, "poise_mult": 1.3, "time_mult": 1.15,
		"cd_mult": {"dashslash": 1.3, "slam": 0.6}, "lifesteal": 0.15,
		"body_color": Color(0.35, 0.05, 0.08), "blade_scale": Vector3(1.8, 1.4, 1.3),
		"pros": ["+35 % poškození, +30 % zdraví, +30 % odolnost", "Léčí 15 % způsobeného poškození", "Úder do země: obnova -40 %"],
		"cons": ["-8 % rychlost pohybu", "Útoky o 15 % pomalejší", "Krok stínu: obnova +30 %"],
		"line": "„Společně je všechny zničíme.“ (původní fanouškovská replika)",
	},
}

static func profile(path: int) -> Dictionary:
	return PROFILES.get(path, PROFILES[Path.HUMAN])
