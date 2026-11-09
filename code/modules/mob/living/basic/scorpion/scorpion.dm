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

	ai_controller = /datum/ai_controller/basic_controller/scorpion

/mob/living/basic/scorpion/Initialize(mapload)
	. = ..()
	update_transform(SCORPION_SPRITE_SCALE)
	AddElement(/datum/element/ai_retaliate)
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_SNAKE, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 5)
	AddElement(/datum/element/venomous, /datum/reagent/toxin, SCORPION_VENOM_DOSE)
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/// Signal proc for [COMSIG_ATOM_ENTERED]. Anything that walks onto us is stung at once, unless it wears thick (THICKMATERIAL) boots, and is added to our retaliate list so we follow up.
/mob/living/basic/scorpion/proc/on_entered(datum/source, atom/movable/entered)
	SIGNAL_HANDLER

	if(!isliving(entered) || entered == src || stat != STABLE)
		return
	var/mob/living/stepper = entered
	if(stepper.incorporeal_move || (stepper.movement_type & (FLYING|FLOATING)) || faction_check_atom(stepper))
		return
	ai_controller?.set_blackboard_key_assoc_lazylist(BB_BASIC_MOB_RETALIATE_LIST, stepper, world.time)
	var/obj/item/clothing/shoes/boots = stepper.get_item_by_slot(ITEM_SLOT_FEET)
	if(istype(boots) && (boots.clothing_flags & THICKMATERIAL))
		to_chat(stepper, span_notice("You step on [src], but your thick boots keep its sting out!"))
		return
	to_chat(stepper, span_warning("You step on [src]!"))
	INVOKE_ASYNC(src, TYPE_PROC_REF(/mob/living/basic, melee_attack), stepper, null, TRUE)

/// Passive like the snake: wanders, and only goes after whatever stepped on it or attacked it.
/datum/ai_controller/basic_controller/scorpion
	behavior_tree_json = "code/modules/mob/living/basic/scorpion/scorpion.bt.json"
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic/not_friends,
	)

	ai_traits = DEFAULT_AI_FLAGS | STOP_MOVING_WHEN_PULLED
	ai_movement = /datum/ai_movement/basic_avoidance

#undef SCORPION_SPRITE_SCALE
#undef SCORPION_VENOM_DOSE
