// Element fuel for emitters. Load a beaker of periodic table elements into an emitter and each
// shot burns a little of the heaviest element in it; heavier atoms make a harder-hitting beam,
// which also pumps more power into the supermatter (its gain scales with beam damage).

/// Units of element burned per emitter shot
#define EMITTER_FUEL_PER_SHOT 1
/// Atomic weight that adds +100% beam damage. Hydrogen is ~1.01x, iron ~1.56x, lead ~3.07x, oganesson ~3.94x
#define EMITTER_FUEL_WEIGHT_PER_FULL_BONUS 100

/obj/machinery/power/emitter
	/// Beaker of element fuel. The heaviest element in it is burned on each shot to strengthen the beam
	var/obj/item/reagent_containers/fuel_beaker

/// Returns the heaviest element in the fuel beaker with at least one shot's worth of fuel, or null
/obj/machinery/power/emitter/proc/get_fuel_element()
	if(QDELETED(fuel_beaker) || !fuel_beaker.reagents?.total_volume)
		return null
	var/datum/periodic_element/heaviest
	for(var/datum/reagent/reagent as anything in fuel_beaker.reagents.reagent_list)
		if(reagent.volume < EMITTER_FUEL_PER_SHOT)
			continue
		var/datum/periodic_element/element = get_periodic_element(reagent)
		if(element && (!heaviest || element.atomic_weight > heaviest.atomic_weight))
			heaviest = element
	return heaviest

/// Beam damage multiplier an element gives as emitter fuel
/proc/get_emitter_fuel_multiplier(datum/periodic_element/element)
	if(!element)
		return 1
	return 1 + element.atomic_weight / EMITTER_FUEL_WEIGHT_PER_FULL_BONUS

/**
 * Burns one shot's worth of the heaviest element in the fuel beaker and strengthens the beam to match.
 * Only emitter beams are boosted, so a gun built into the emitter doesn't become a heavier turret.
 * Returns the element burned, or null if nothing was.
 */
/obj/machinery/power/emitter/proc/burn_element_fuel(obj/projectile/projectile)
	if(!istype(projectile, /obj/projectile/beam/emitter))
		return null
	var/datum/periodic_element/element = get_fuel_element()
	if(!element)
		return null
	fuel_beaker.reagents.remove_reagent(element.reagent_type, EMITTER_FUEL_PER_SHOT)
	projectile.damage *= get_emitter_fuel_multiplier(element)
	projectile.name = "[LOWER_TEXT(element.name)]-charged [projectile.name]"
	return element

/// Swaps the fuel beaker for new_beaker, or just ejects it if new_beaker is null. Returns TRUE on success
/obj/machinery/power/emitter/proc/replace_fuel_beaker(mob/living/user, obj/item/reagent_containers/new_beaker)
	if(new_beaker && !user.transferItemToLoc(new_beaker, src))
		return FALSE
	if(!QDELETED(fuel_beaker))
		try_put_in_hand(fuel_beaker, user)
	fuel_beaker = new_beaker
	return TRUE

/// Examine lines describing the fuel port
/obj/machinery/power/emitter/proc/get_fuel_examine()
	. = list()
	if(!fuel_beaker)
		. += span_info("It has a fuel port that takes a beaker of elements. Heavier elements make a stronger beam.")
		return
	. += span_info("It has \a [fuel_beaker] loaded in its fuel port. <b>Right-click</b> with an empty hand to remove it.")
	var/datum/periodic_element/element = get_fuel_element()
	if(element)
		. += span_notice("Its fuel display reads: <b>[element.name]</b> ([element.symbol], [element.atomic_weight] u), beam strength <b>[round(get_emitter_fuel_multiplier(element) * 100)]%</b>.")
	else
		. += span_warning("Its fuel display reads: <b>no usable element</b>.")

/// Loads or swaps a fuel beaker from an item interaction
/obj/machinery/power/emitter/proc/try_load_fuel(mob/living/user, obj/item/reagent_containers/beaker)
	var/had_beaker = !!fuel_beaker
	if(!replace_fuel_beaker(user, beaker))
		balloon_alert(user, "stuck in hand!")
		return ITEM_INTERACT_BLOCKING
	balloon_alert(user, had_beaker ? "fuel swapped" : "fuel loaded")
	playsound(src, 'sound/items/handling/beaker_place.ogg', 50, TRUE)
	return ITEM_INTERACT_SUCCESS

#undef EMITTER_FUEL_PER_SHOT
#undef EMITTER_FUEL_WEIGHT_PER_FULL_BONUS
