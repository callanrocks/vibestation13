/// Mammoths are calm, wander, eat, and fight back hard when someone hits them.
/datum/ai_controller/basic_controller/mammoth
	behavior_tree_json = "code/modules/mob/living/basic/farm_animals/mammoth/mammoth.bt.json"
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_BASIC_MOB_SPEAK_LINES = list(
			BB_EMOTE_SEE = list("swings its trunk.", "flaps its ears.", "sniffs the air."),
			BB_SPEAK_CHANCE = 2,
		),
	)

	ai_traits = DEFAULT_AI_FLAGS | STOP_MOVING_WHEN_PULLED
	ai_movement = /datum/ai_movement/basic_avoidance

/// Finds food in priority order: loose food first, then harvested crops, then growing plants.
/datum/bt_node/subtree/mammoth_find_food
	behavior_tree_json = "code/modules/mob/living/basic/farm_animals/mammoth/mammoth_find_food.bt.json"

/// How far around the mammoth a better kind of food stops it from going for a worse one.
#define MAMMOTH_FOOD_PRIORITY_RANGE 7

/// Accepts loose food, harvested crops, and trays with a growing plant, but only when nothing better is nearby.
/datum/targeting_strategy/pickup_item/mammoth_food

/datum/targeting_strategy/pickup_item/mammoth_food/is_valid_target(mob/living/living_mob, atom/target, vision_range, datum/ai_controller/controller = null)
	. = ..()
	if(!.)
		return FALSE
	var/tier = get_food_tier(target)
	if(!tier)
		return FALSE
	if(tier == 1)
		return TRUE
	for(var/obj/item/food/other in oview(MAMMOTH_FOOD_PRIORITY_RANGE, living_mob))
		if(isturf(other.loc) && get_food_tier(other) < tier)
			return FALSE
	return TRUE

/// 1 = loose food, 2 = harvested crop, 3 = growing plant in a tray, 0 = not food.
/datum/targeting_strategy/pickup_item/mammoth_food/proc/get_food_tier(atom/thing)
	if(istype(thing, /obj/machinery/hydroponics))
		var/obj/machinery/hydroponics/tray = thing
		return (tray.myseed && tray.plant_status != HYDROTRAY_NO_PLANT) ? 3 : 0
	if(istype(thing, /obj/item/food/grown))
		return 2
	if(istype(thing, /obj/item/food))
		return 1
	return 0

#undef MAMMOTH_FOOD_PRIORITY_RANGE
