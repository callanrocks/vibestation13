/// Sprite scale of the scorpion. Visual only, stats are not touched.
#define SCORPION_SPRITE_SCALE 0.5
/// Units of venom injected per sting.
#define SCORPION_VENOM_DOSE 4

/// A small desert-dwelling arthropod that stings with a toxic tail. The sprite is drawn at 32x32 and shrunk to half size.
/mob/living/basic/scorpion
	name = "scorpion"
	desc = "A pincered arachnid with a venomous, curled tail. Small, but it will not hesitate to sting."
	icon = 'icons/mob/simple/scorpion.dmi'
	icon_state = "scorpion"
	icon_living = "scorpion"
	icon_dead = "scorpion_dead"

	speak_emote = list("clicks")
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "shoos"
	response_disarm_simple = "shoo"
	response_harm_continuous = "squashes"
	response_harm_simple = "squash"
	attack_verb_continuous = "stings"
	attack_verb_simple = "sting"
	attack_sound = 'sound/items/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE

	faction = list(FACTION_HOSTILE)
	mob_biotypes = MOB_ORGANIC | MOB_BUG
	mob_size = MOB_SIZE_TINY
	pass_flags = PASSTABLE | PASSMOB
	density = FALSE

	health = 5
	maxHealth = 5
	melee_damage_lower = 1
	melee_damage_upper = 1
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE

	ai_controller = /datum/ai_controller/basic_controller/simple/simple_hostile

/mob/living/basic/scorpion/Initialize(mapload)
	. = ..()
	update_transform(SCORPION_SPRITE_SCALE)
	AddElement(/datum/element/ai_retaliate)
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_SNAKE, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 5)
	AddElement(/datum/element/venomous, /datum/reagent/toxin, SCORPION_VENOM_DOSE)

#undef SCORPION_SPRITE_SCALE
#undef SCORPION_VENOM_DOSE
