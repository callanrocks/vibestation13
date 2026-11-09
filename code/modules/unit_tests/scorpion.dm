/// Stepping onto a scorpion stings the stepper with toxin straight away.
/datum/unit_test/scorpion_step_on_sting

/datum/unit_test/scorpion_step_on_sting/Run()
	var/mob/living/basic/scorpion/scorpion = allocate(/mob/living/basic/scorpion)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	scorpion.forceMove(get_step(victim, EAST))

	victim.forceMove(scorpion.loc)
	sleep(1)
	TEST_ASSERT(victim.reagents.has_reagent(/datum/reagent/toxin), "A barefoot human who stepped on a scorpion was not injected with toxin.")

/// Thick boots stop the step-on sting.
/datum/unit_test/scorpion_thick_boots

/datum/unit_test/scorpion_thick_boots/Run()
	var/mob/living/basic/scorpion/scorpion = allocate(/mob/living/basic/scorpion)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	var/obj/item/clothing/shoes/boots = allocate(/obj/item/clothing/shoes/winterboots/ice_boots/eva)
	TEST_ASSERT(boots.clothing_flags & THICKMATERIAL, "The test boots are no longer THICKMATERIAL, pick other thick boots.")
	victim.equip_to_slot_if_possible(boots, ITEM_SLOT_FEET, disable_warning = TRUE)
	scorpion.forceMove(get_step(victim, EAST))

	victim.forceMove(scorpion.loc)
	sleep(1)
	TEST_ASSERT(!victim.reagents.has_reagent(/datum/reagent/toxin), "A human in thick boots was injected with toxin by a scorpion.")
	var/list/retaliate_list = scorpion.ai_controller.blackboard[BB_BASIC_MOB_RETALIATE_LIST]
	TEST_ASSERT(LAZYACCESS(retaliate_list, victim), "A scorpion stepped on by someone in thick boots did not add them to its retaliate list.")

/// A dead scorpion does nothing when stepped on.
/datum/unit_test/scorpion_dead_no_sting

/datum/unit_test/scorpion_dead_no_sting/Run()
	var/mob/living/basic/scorpion/scorpion = allocate(/mob/living/basic/scorpion)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	scorpion.forceMove(get_step(victim, EAST))
	scorpion.death()

	victim.forceMove(scorpion.loc)
	sleep(1)
	TEST_ASSERT(!victim.reagents.has_reagent(/datum/reagent/toxin), "A dead scorpion stung someone who stepped on it.")

/// The scorpion has the design doc stats and is drawn at half size.
/datum/unit_test/scorpion_stats

/datum/unit_test/scorpion_stats/Run()
	var/mob/living/basic/scorpion/scorpion = allocate(/mob/living/basic/scorpion)
	TEST_ASSERT_EQUAL(scorpion.maxHealth, 5, "Scorpion max health is not 5.")
	TEST_ASSERT_EQUAL(scorpion.melee_damage_lower, 1, "Scorpion minimum melee damage is not 1.")
	TEST_ASSERT_EQUAL(scorpion.melee_damage_upper, 1, "Scorpion maximum melee damage is not 1.")
	TEST_ASSERT_EQUAL(scorpion.current_size, 0.5, "Scorpion sprite is not scaled to 50%.")
