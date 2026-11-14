/// The abductor chem gland must only pick reagents that exist, and never the periodic-table toxins.
/datum/unit_test/abductor_chem_gland

/datum/unit_test/abductor_chem_gland/Run()
	var/obj/item/organ/heart/gland/chem/gland = allocate(/obj/item/organ/heart/gland/chem)
	TEST_ASSERT(length(gland.possible_reagents), "The chem gland has no reagents to pick from")
	for(var/reagent_type in gland.possible_reagents)
		TEST_ASSERT(GLOB.chemical_reagents_list[reagent_type], "The chem gland can pick unusable reagent [reagent_type]")
		TEST_ASSERT(!ispath(reagent_type, /datum/reagent/toxin/element), "The chem gland can pick periodic-table toxin [reagent_type]")
