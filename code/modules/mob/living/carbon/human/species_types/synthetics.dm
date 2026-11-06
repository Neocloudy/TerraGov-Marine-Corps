/datum/species/synthetic
	name = "Synthetic"
	default_language_holder = /datum/language_holder/synthetic
	unarmed_type = /datum/unarmed_attack/punch
	limb_type = SPECIES_LIMB_HUMAN

	total_health = 125 //more health than regular humans

	brute_mod = 0.8
	burn_mod = 0.8 // A slight amount of burn resistance. Changed from 0.7 due to their critical condition phase

	cold_level_1 = -1
	cold_level_2 = -1
	cold_level_3 = -1

	heat_level_1 = 500
	heat_level_2 = 1000
	heat_level_3 = 2000

	body_temperature = 350

	species_flags = NO_BREATHE|NO_BLOOD|NO_POISON|NO_PAIN|IS_SYNTHETIC|NO_CHEM_METABOLIZATION|NO_STAMINA|DETACHABLE_HEAD|HAS_LIPS|HAS_UNDERWEAR|HAS_SKIN_COLOR|ROBOTIC_LIMBS|GREYSCALE_BLOOD|SPECIES_NO_HUG

	blood_color = "#EEEEEE"

	has_organ = list()

	lighting_cutoff = LIGHTING_CUTOFF_HIGH

	screams = list(MALE = SFX_MALE_SCREAM, FEMALE = SFX_FEMALE_SCREAM)
	paincries = list(MALE = SFX_MALE_PAIN, FEMALE = SFX_FEMALE_PAIN)
	goredcries = list(MALE = SFX_MALE_GORED, FEMALE = SFX_FEMALE_GORED)
	warcries = list(MALE = SFX_MALE_WARCRY, FEMALE = SFX_FEMALE_WARCRY)
	special_death_message = "You have been shut down.<br><small>But it is not the end of you yet... if you still have your body, wait until somebody can resurrect you...</small>"

	/// Threshold for special crit behavior
	var/crit_thresh = 0
	/// Threshold where the crit grace period is cancelled/skipped and damage starts immediately
	var/severe_crit_thresh = -35
	/// Time to start crit damage
	var/crit_damage_time = 15 SECONDS
	/// Timer ID for starting crit burn damage
	var/crit_damage_timerid
	/// If crit burn damage is actually active
	var/crit_damage_active = FALSE
	/// Lowest percentage of max health dealt as damage when in crit
	var/crit_damage_percentage_low = 0.035
	/// Highest percentage of max health dealt as damage when in crit
	var/crit_damage_percentage_high = 0.09
	/// Armor reduction while in negative health
	var/crit_armor_reduction = 1.2
	/// Holder for armor reduction
	var/datum/armor/crit_armor_modifier

/datum/species/synthetic/handle_unique_behavior(mob/living/carbon/human/human)
	if(human.stat == DEAD)
		return
	if(human.health <= crit_thresh)
		special_crit(human)
	else if(crit_damage_active)
		clear_crit_timerid()
		crit_damage_end(human)

/// Called while health is below [crit_thresh], any effects of being in critical condition
/datum/species/synthetic/proc/special_crit(mob/living/carbon/human/human)
	if(crit_damage_active)
		crit_damage_tick(human)
		return

	if(human.health <= severe_crit_thresh)
		// if this synth is fucked enough, just start killing them anyway
		crit_damage_start(human)
		crit_armor_shred(human)
		return

	if(!crit_damage_timerid)
		start_crit_timer(human)
		crit_armor_shred(human)
		return

/// Applies critical condition armor reduction
/datum/species/synthetic/proc/crit_armor_shred(mob/living/carbon/human/human)
	if(crit_armor_modifier)
		return
	crit_armor_modifier = human.soft_armor.scaleAllRatings(crit_armor_reduction)
	human.soft_armor = human.soft_armor.detachArmor(crit_armor_modifier)

/// Cleanses critical condition armor reduction
/datum/species/synthetic/proc/crit_armor_unshred(mob/living/carbon/human/human)
	human.soft_armor = human.soft_armor.attachArmor(crit_armor_modifier)
	QDEL_NULL(crit_armor_modifier)

/// Clears the critical condition timer ID
/datum/species/synthetic/proc/clear_crit_timerid()
	if(!crit_damage_timerid)
		return
	deltimer(crit_damage_timerid)
	crit_damage_timerid = null

/// Starts the critical condition timer
/datum/species/synthetic/proc/start_crit_timer(mob/living/carbon/human/human)
	crit_damage_timerid = addtimer(CALLBACK(src, PROC_REF(crit_damage_start), human), crit_damage_time, TIMER_STOPPABLE | TIMER_DELETE_ME)
	to_chat(human, span_userdanger("Critical damage sustained. Internal temperature regulation systems failing. Integrity compromised. <i>Survival estimate: [DisplayTimeText(crit_damage_time + rand(-3 SECONDS, 7 SECONDS))].</i>"))
	human.balloon_alert(human, "integrity warning!")

/// Starts the actual damage over time from critical condition
/datum/species/synthetic/proc/crit_damage_start(mob/living/carbon/human/human)
	if(crit_damage_active)
		return
	crit_damage_active = TRUE
	do_sparks(4, TRUE, human)
	human.balloon_alert(human, "burning up!")
	human.visible_message(
		span_danger("[human] staggers, sparks flying out from [human.p_their(TRUE)] chest!"),
		span_userdanger("Critical damage sustained. Internal temperature regulation systems offline. <i>Shutdown imminent.</i>"),
	)

/// Called while [crit_damage_active] is TRUE, the negative effects of being in crit for too long
/datum/species/synthetic/proc/crit_damage_tick(mob/living/carbon/human/human)
	human.adjustFireLossByPart(rand(total_health * crit_damage_percentage_low, total_health * crit_damage_percentage_high), /datum/limb/chest::name)
	human.updatehealth()
	if(prob(18))
		human.visible_message(
			span_boldwarning("[human] shudders violently and shoots out sparks!"),
			span_warning("Critical damage sustained. Internal temperature regulation systems offline. Shutdown imminent. <b>Estimated integrity: [round(human.health)]%.</b>"),
		)
		do_sparks(4, TRUE, human)

/// Stops the actual damage over time from critical condition
/datum/species/synthetic/proc/crit_damage_end(mob/living/carbon/human/human)
	crit_damage_active = FALSE
	to_chat(human, span_boldnotice("Critical damage repaired. Internal temperature regulation systems active."))
	human.balloon_alert(human, "integrity restored")
	crit_armor_unshred(human)

/datum/species/synthetic/on_species_gain(mob/living/carbon/human/human, datum/species/old_species)
	. = ..()
	var/datum/atom_hud/AH = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED_SYNTH]
	AH.add_hud_to(human)
	human.health_threshold_crit *= 2 // we do our own custom handling of this

/datum/species/synthetic/post_species_loss(mob/living/carbon/human/human)
	. = ..()
	var/datum/atom_hud/AH = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED_SYNTH]
	AH.remove_hud_from(human)
	human.health_threshold_crit = initial(human.health_threshold_crit)

/mob/living/carbon/human/species/synthetic/binarycheck(mob/human)
	return TRUE

/datum/species/synthetic/prefs_name(datum/preferences/prefs)
	. = prefs.synthetic_name
	if(!. || . == "Undefined") //In case they don't have a name set
		switch(prefs.gender)
			if(MALE)
				. = "David"
			if(FEMALE)
				. = "Anna"
			else
				. = "Jeri"
		to_chat(prefs.parent, span_warning("You forgot to set your synthetic name in your preferences. Please do so next time."))

/datum/species/synthetic/early
	name = "Early Synthetic"
	icobase = 'icons/mob/human_races/r_synthetic.dmi'
	limb_type = SPECIES_LIMB_GENERIC
	species_flags = parent_type::species_flags ^ (HAS_LIPS | HAS_SKIN_COLOR)
	hair_color = "#000000"

	slowdown = 1.15
	total_health = 200
	brute_mod = 0.65
	burn_mod = 0.65

	crit_damage_time = parent_type::crit_damage_time / 2
	crit_armor_reduction = 1.35
