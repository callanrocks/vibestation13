/// Makes sure the mammoth's trunk crush stays inside its damage cap and the throw knocks the target down.
/datum/unit_test/mammoth_trunk

/datum/unit_test/mammoth_trunk/Run()
	var/mob/living/basic/mammoth/mammoth = allocate(/mob/living/basic/mammoth)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	mammoth.forceMove(get_step(victim, EAST))

	mammoth.trunk_crush(victim, MAMMOTH_CRUSH_DAMAGE)
	var/crush_damage = victim.get_brute_loss()
	TEST_ASSERT(crush_damage > 0, "The crush did no damage.")
	TEST_ASSERT(crush_damage <= MAMMOTH_CRUSH_DAMAGE, "The crush did [crush_damage] damage, over the cap of [MAMMOTH_CRUSH_DAMAGE].")
	TEST_ASSERT(victim.health > 0, "A single crush on a healthy human left them at or below zero health.")

	victim.fully_heal(HEAL_ALL)
	mammoth.trunk_throw(victim)
	sleep(2 SECONDS)
	TEST_ASSERT(victim.IsKnockdown(), "The thrown target was not knocked down after landing.")
