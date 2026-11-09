/// Placeholder trumpet sound. There is no elephant sound in the repo, so swap this one define when a real file exists.
#define MAMMOTH_TRUMPET_SOUND 'sound/mobs/non-humanoids/gorilla/gorilla.ogg'

/// How long the trunk holds a target before rolling an outcome. The target can resist out of it.
#define MAMMOTH_GRAB_HOLD_TIME (2 SECONDS)
/// Time between trunk grabs.
#define MAMMOTH_GRAB_COOLDOWN (30 SECONDS)

/// Outcome odds, out of 100. Throw takes the rest of the roll after crush and combo are taken off.
#define MAMMOTH_CHANCE_CRUSH 30
#define MAMMOTH_CHANCE_CRUSH_THEN_THROW 20
// Throw is the remaining 50.

/// Brute damage of a plain crush.
#define MAMMOTH_CRUSH_DAMAGE 30
/// Brute damage of the crush that comes before a throw. Lower so the combo stays survivable.
#define MAMMOTH_COMBO_CRUSH_DAMAGE 20
/// Chance for a crush to break a bone (a moderate blunt wound, never worse).
#define MAMMOTH_BONE_BREAK_CHANCE 50

/// Tiles a thrown target flies.
#define MAMMOTH_THROW_RANGE_MIN 3
#define MAMMOTH_THROW_RANGE_MAX 5
/// How long a thrown target is knocked down after landing.
#define MAMMOTH_THROW_KNOCKDOWN (3 SECONDS)

/// Cooldown between trumpets when it is happy.
#define MAMMOTH_HAPPY_TRUMPET_COOLDOWN (30 SECONDS)
/// Chance per second to trumpet while idle, fed, and off cooldown.
#define MAMMOTH_HAPPY_TRUMPET_CHANCE 2
/// It counts as well fed for this long after eating.
#define MAMMOTH_FED_WINDOW (3 MINUTES)
/// Cooldown between trumpets when it starts fighting back.
#define MAMMOTH_RETALIATE_TRUMPET_COOLDOWN (15 SECONDS)
/// Chance for it to say "Nom" after a bite.
#define MAMMOTH_NOM_CHANCE 30
/// Pause between meals, so it does not clear a whole tray in seconds.
#define MAMMOTH_EAT_COOLDOWN (10 SECONDS)

/// A big, peaceful farm animal that eats crops and food, trumpets, and grabs anyone who hits it.
/mob/living/basic/mammoth
	name = "mammoth"
	desc = "A huge, shaggy relative of the elephant. It is gentle until you hit it."
	icon = 'icons/mob/simple/mammoth.dmi'
	icon_state = "mammoth"
	icon_living = "mammoth"
	icon_dead = "mammoth_dead"

	speak_emote = list("trumpets")
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "slams"
	response_harm_simple = "slam"
	attack_verb_continuous = "slams"
	attack_verb_simple = "slam"
	attack_sound = 'sound/items/weapons/punch1.ogg'
	attack_vis_effect = ATTACK_EFFECT_SMASH

	butcher_results = list(/obj/item/food/meat/slab/grassfed = 8)

	faction = list(FACTION_NEUTRAL)
	mob_biotypes = MOB_ORGANIC | MOB_BEAST
	mob_size = MOB_SIZE_LARGE

	health = 200
	maxHealth = 200
	melee_damage_lower = 12
	melee_damage_upper = 18
	obj_damage = 30
	wound_bonus = 0
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES

	minimum_survivable_temperature = COLD_ROOM_TEMP - 75 // spawns next to Pete in the cold room
	default_blood_volume = BLOOD_VOLUME_NORMAL

	ai_controller = /datum/ai_controller/basic_controller/mammoth

	/// Extra attack words picked at random on top of the base verb.
	var/static/list/attack_verbs = list("slaps", "kicks", "slams")
	/// Things it eats off the ground or out of trays.
	var/static/list/edibles = list(
		/obj/item/food,
		/obj/machinery/hydroponics,
	)
	/// True while the trunk is holding someone.
	var/grabbing = FALSE
	/// World time of the last meal.
	var/last_ate = -INFINITY
	COOLDOWN_DECLARE(grab_cooldown)
	COOLDOWN_DECLARE(happy_trumpet_cooldown)
	COOLDOWN_DECLARE(retaliate_trumpet_cooldown)

/mob/living/basic/mammoth/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/footstep, footstep_type = FOOTSTEP_MOB_SHOE)
	AddElement(/datum/element/ai_retaliate)
	AddElement(/datum/element/basic_eating, food_types = list(/obj/item/food))
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_COW, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 5)

	RegisterSignal(src, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	RegisterSignal(src, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_attacked))
	RegisterSignal(src, COMSIG_MOB_ATE, PROC_REF(on_ate))

	ai_controller.set_blackboard_key(BB_BASIC_FOODS, typecacheof(edibles))
	ai_controller.set_blackboard_key(BB_EAT_FOOD_COOLDOWN, MAMMOTH_EAT_COOLDOWN)

/mob/living/basic/mammoth/Life(seconds_per_tick = SSMOBS_DT)
	. = ..()
	if(stat != CONSCIOUS || grabbing || (world.time > last_ate + MAMMOTH_FED_WINDOW))
		return
	if(!COOLDOWN_FINISHED(src, happy_trumpet_cooldown) || !isnull(ai_controller?.blackboard[BB_CURRENT_TARGET]))
		return
	if(SPT_PROB(MAMMOTH_HAPPY_TRUMPET_CHANCE, seconds_per_tick))
		COOLDOWN_START(src, happy_trumpet_cooldown, MAMMOTH_HAPPY_TRUMPET_COOLDOWN)
		trumpet()

/// Raises its trunk, emotes, and plays the sound.
/mob/living/basic/mammoth/proc/trumpet()
	if(stat == DEAD)
		return
	manual_emote("trumpets loudly!")
	playsound(src, MAMMOTH_TRUMPET_SOUND, 75, TRUE)
	icon_state = "mammoth_trumpet"
	addtimer(CALLBACK(src, PROC_REF(end_trumpet)), 1.5 SECONDS)

/mob/living/basic/mammoth/proc/end_trumpet()
	if(stat == DEAD)
		return
	icon_state = icon_living

/// Trumpet once when someone first hits it, so bystanders get a warning that a grab may follow.
/mob/living/basic/mammoth/proc/on_attacked(datum/source, atom/attacker, attack_flags)
	SIGNAL_HANDLER
	if(stat == DEAD || !COOLDOWN_FINISHED(src, retaliate_trumpet_cooldown))
		return
	COOLDOWN_START(src, retaliate_trumpet_cooldown, MAMMOTH_RETALIATE_TRUMPET_COOLDOWN)
	INVOKE_ASYNC(src, PROC_REF(trumpet))

/mob/living/basic/mammoth/proc/on_ate(datum/source, atom/food, mob/living/feeder)
	SIGNAL_HANDLER
	last_ate = world.time
	if(prob(MAMMOTH_NOM_CHANCE))
		INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/movable, say), "Nom")

/// Eats the plant in a hydroponics tray when it bumps one. Food items are handled by the basic_eating element.
/mob/living/basic/mammoth/proc/on_unarmed_attack(datum/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(!proximity || !istype(target, /obj/machinery/hydroponics))
		return NONE
	var/obj/machinery/hydroponics/tray = target
	if(isnull(tray.myseed) || tray.plant_status == HYDROTRAY_NO_PLANT)
		return NONE
	visible_message(span_notice("[src] munches the plants in [tray]."))
	playsound(src, 'sound/items/eatfood.ogg', rand(30, 50), TRUE)
	tray.set_seed(null)
	SEND_SIGNAL(src, COMSIG_MOB_ATE, tray, null)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/mob/living/basic/mammoth/melee_attack(atom/target, list/modifiers, ignore_cooldown = FALSE)
	if(isliving(target) && can_trunk_grab(target))
		face_atom(target)
		COOLDOWN_START(src, grab_cooldown, MAMMOTH_GRAB_COOLDOWN)
		changeNext_move(MAMMOTH_GRAB_HOLD_TIME)
		INVOKE_ASYNC(src, PROC_REF(trunk_grab), target)
		return TRUE
	// Normal hit, with a random verb for flavour.
	attack_verb_continuous = pick(attack_verbs)
	attack_verb_simple = copytext(attack_verb_continuous, 1, -1)
	return ..()

/// Grabs only fight-back targets that are alive, adjacent, not another mammoth, and only when off cooldown.
/mob/living/basic/mammoth/proc/can_trunk_grab(mob/living/target)
	if(grabbing || stat != CONSCIOUS || !COOLDOWN_FINISHED(src, grab_cooldown))
		return FALSE
	if(target.stat == DEAD || istype(target, /mob/living/basic/mammoth) || target.anchored)
		return FALSE
	return Adjacent(target)

/// Whether the hold is still going: both alive, still adjacent, and the target has not broken free.
/mob/living/basic/mammoth/proc/trunk_hold_valid(mob/living/target)
	if(QDELETED(src) || QDELETED(target) || stat != CONSCIOUS || target.stat == DEAD)
		return FALSE
	if(HAS_TRAIT(src, TRAIT_INCAPACITATED) || pulling != target)
		return FALSE
	return Adjacent(target)

/// The grab: warn, hold briefly, then roll an outcome unless the target broke free or the mammoth was stopped.
/mob/living/basic/mammoth/proc/trunk_grab(mob/living/target)
	grabbing = TRUE
	if(!start_pulling(target, GRAB_AGGRESSIVE, supress_message = TRUE))
		grabbing = FALSE
		COOLDOWN_RESET(src, grab_cooldown)
		return
	visible_message(
		span_userdanger("[src] wraps its trunk around [target]!"),
		span_notice("You wrap your trunk around [target]."),
	)
	var/hold_end = world.time + MAMMOTH_GRAB_HOLD_TIME
	while(world.time < hold_end)
		sleep(0.25 SECONDS)
		if(!trunk_hold_valid(target))
			break
	var/held = trunk_hold_valid(target)
	if(pulling == target)
		stop_pulling()
	grabbing = FALSE
	if(!held)
		if(!QDELETED(target) && !QDELETED(src))
			visible_message(span_warning("[target] slips out of [src]'s trunk!"))
		return
	var/roll = rand(1, 100)
	if(roll <= MAMMOTH_CHANCE_CRUSH)
		trunk_crush(target, MAMMOTH_CRUSH_DAMAGE)
	else if(roll <= MAMMOTH_CHANCE_CRUSH + MAMMOTH_CHANCE_CRUSH_THEN_THROW)
		trunk_crush(target, MAMMOTH_COMBO_CRUSH_DAMAGE)
		trunk_throw(target)
	else
		trunk_throw(target)

/// Throws the target away from the mammoth and knocks them down on landing.
/mob/living/basic/mammoth/proc/trunk_throw(mob/living/target)
	if(QDELETED(target))
		return
	visible_message(span_userdanger("[src] hurls [target] through the air!"))
	playsound(src, 'sound/items/weapons/punch1.ogg', 60, TRUE)
	var/throw_range = rand(MAMMOTH_THROW_RANGE_MIN, MAMMOTH_THROW_RANGE_MAX)
	var/turf/destination = get_edge_target_turf(target, get_dir(src, target))
	target.throw_at(destination, throw_range, 2, thrower = src, callback = CALLBACK(target, TYPE_PROC_REF(/mob/living, Knockdown), MAMMOTH_THROW_KNOCKDOWN))

/// Crushes the target for fixed damage, with a chance of a broken bone on humans and other mobs with limbs.
/mob/living/basic/mammoth/proc/trunk_crush(mob/living/target, damage)
	if(QDELETED(target))
		return
	visible_message(span_userdanger("[src] crushes [target] in its trunk!"))
	playsound(src, 'sound/effects/wounds/crack2.ogg', 70, TRUE)
	if(!iscarbon(target))
		target.apply_damage(damage, BRUTE)
		return
	var/mob/living/carbon/victim = target
	var/list/candidates = list()
	for(var/obj/item/bodypart/part as anything in victim.bodyparts)
		if(part.body_zone != BODY_ZONE_HEAD)
			candidates += part
	if(!length(candidates))
		victim.apply_damage(damage, BRUTE)
		return
	var/obj/item/bodypart/crushed = pick(candidates)
	victim.apply_damage(damage, BRUTE, crushed.body_zone)
	if(prob(MAMMOTH_BONE_BREAK_CHANCE))
		victim.cause_wound_of_type_and_severity(WOUND_BLUNT, crushed, WOUND_SEVERITY_MODERATE, WOUND_SEVERITY_MODERATE, wound_source = src)
