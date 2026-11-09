/// Checks that emitters burn the heaviest loaded element per shot and scale beam damage by its atomic weight.
/datum/unit_test/emitter_element_fuel

/datum/unit_test/emitter_element_fuel/Run()
	var/obj/machinery/power/emitter/emitter = allocate(/obj/machinery/power/emitter)
	var/obj/item/reagent_containers/cup/beaker/beaker = allocate(/obj/item/reagent_containers/cup/beaker)
	var/datum/periodic_element/hydrogen = GLOB.periodic_table[1]
	var/datum/periodic_element/lead = GLOB.periodic_table[82]

	// No fuel: the beam is untouched
	var/obj/projectile/beam/emitter/hitscan/plain_beam = allocate(/obj/projectile/beam/emitter/hitscan)
	var/base_damage = plain_beam.damage
	TEST_ASSERT_NULL(emitter.burn_element_fuel(plain_beam), "An empty emitter burned fuel")
	TEST_ASSERT_EQUAL(plain_beam.damage, base_damage, "An empty emitter changed beam damage")

	// Non-elements are ignored
	beaker.reagents.add_reagent(/datum/reagent/water, 10)
	beaker.forceMove(emitter)
	emitter.fuel_beaker = beaker
	TEST_ASSERT_NULL(emitter.burn_element_fuel(plain_beam), "Water was burned as emitter fuel")
	TEST_ASSERT_EQUAL(beaker.reagents.get_reagent_amount(/datum/reagent/water), 10, "Water was consumed as emitter fuel")

	// The heaviest element is burned, one unit per shot
	beaker.reagents.add_reagent(hydrogen.reagent_type, 10)
	beaker.reagents.add_reagent(lead.reagent_type, 10)
	var/obj/projectile/beam/emitter/hitscan/lead_beam = allocate(/obj/projectile/beam/emitter/hitscan)
	TEST_ASSERT_EQUAL(emitter.burn_element_fuel(lead_beam), lead, "The emitter didn't pick the heaviest element")
	TEST_ASSERT_EQUAL(beaker.reagents.get_reagent_amount(lead.reagent_type), 9, "A shot didn't burn exactly one unit of lead")
	TEST_ASSERT_EQUAL(beaker.reagents.get_reagent_amount(hydrogen.reagent_type), 10, "A lead shot burned hydrogen")
	var/expected = base_damage * get_emitter_fuel_multiplier(lead)
	TEST_ASSERT(abs(lead_beam.damage - expected) < 0.01, "Lead beam did [lead_beam.damage] damage, expected [expected]")
	TEST_ASSERT(lead_beam.damage > base_damage * 3, "Lead should roughly triple beam damage")

	// Heavier elements hit harder than lighter ones
	TEST_ASSERT(get_emitter_fuel_multiplier(lead) > get_emitter_fuel_multiplier(hydrogen), "Lead isn't stronger fuel than hydrogen")

	// Removing the beaker clears the fuel port
	beaker.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(emitter.fuel_beaker, "The emitter kept a reference to a removed fuel beaker")
