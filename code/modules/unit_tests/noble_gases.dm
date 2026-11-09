/// Checks the noble gas elements: each has a matching atmos gas, spilling its reagent releases that gas, and radon irradiates whoever breathes it.
/datum/unit_test/noble_gases

/datum/unit_test/noble_gases/Run()
	var/turf/open/floor = run_loc_floor_bottom_left
	TEST_ASSERT(istype(floor), "The test turf isn't an open turf")

	var/checked = 0
	for(var/datum/periodic_element/element as anything in GLOB.periodic_table)
		if(element.category != ELEMENT_CATEGORY_NOBLE_GAS)
			continue

		var/datum/reagent/reagent = GLOB.chemical_reagents_list[element.reagent_type]
		var/gas_id = reagent?.vars["gas_id"]
		if(isnull(gas_id))
			TEST_FAIL("[element.name] is a noble gas but its reagent releases no gas")
			continue

		var/gas_path = gas_id2path(gas_id)
		if(!gas_path)
			TEST_FAIL("[element.name] releases the gas id '[gas_id]', which isn't an atmos gas")
			continue

		var/gas_name = GLOB.meta_gas_info[META_GAS_NAME][gas_path]
		TEST_ASSERT_EQUAL(gas_name, element.name, "The gas released by [element.name] has the wrong name")

		var/before = floor.air.moles[gas_path] || 0
		reagent.expose_turf(floor, 20)
		var/after = floor.air.moles[gas_path] || 0
		if(after <= before)
			TEST_FAIL("Spilling [element.name] on a turf didn't add any [gas_name]")
		checked++

	// Helium, neon, argon, krypton, xenon and radon
	TEST_ASSERT_EQUAL(checked, 6, "Wrong number of noble gas elements checked")

	// Breathing radon irradiates you
	var/mob/living/carbon/human/lab_rat = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/organ/lungs/test_lungs = allocate(/obj/item/organ/lungs)
	test_lungs.radon_irradiation_probability_min = 100
	test_lungs.radon_irradiation_probability_max = 100
	var/datum/gas_mixture/breath = allocate(/datum/gas_mixture)
	breath.add_gas(/datum/gas/radon)
	breath.moles[/datum/gas/radon] = 5

	TEST_ASSERT(!HAS_TRAIT(lab_rat, TRAIT_IRRADIATED), "The test mob started out irradiated")
	test_lungs.too_much_radon(lab_rat, breath, 10, 0)
	TEST_ASSERT(HAS_TRAIT(lab_rat, TRAIT_IRRADIATED), "Breathing radon didn't irradiate the breather")
	TEST_ASSERT_EQUAL(breath.moles[/datum/gas/radon] || 0, 0, "Radon wasn't removed from the breath")
