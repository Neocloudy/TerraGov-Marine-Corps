/**
 * This is a datum and not a component since it's hopefully more flexible this way.
 * We can (re)use this datam wherever we want, with hopefully little effort for
 * adding it to new atoms.
 *
 * An example use case for this is sharing the same functionality between health analyzers,
 * suit medical systems, body scanners, and more.
 *
 * Can either be instantiated on atom init or only instantiated when you first need it.
 * In either case, it's designed with reusage in mind.
 *
 * For best results, scan patients should be carbon humans, but they may work with any mob.
 *
 * When the time comes to use this, create it as usual with `new()`.
 *
 * * **When instantiating:**
 *
 * * Make sure to set `save_old_scans` accordingly.
 * * Keep it off if you won't need the data later - eg, health analyzers have it on since they can see old scans.
 * * Use `set_memory()` for our first user/patient
 * * Use `attempt_interact()` when trying to let something see the scan. Do not use `ui_interact()`
 *
 * * **After it's instantiated, and when you're reusing it:**
 *
 * * Use `set_memory()` when the user/patient changes (like when doing another scan)
 * * Use `attempt_interact()` when trying to let something see the scan. Do not use `ui_interact()`
 * * Use `clear_memory()` accordingly when the old user/patient will not be relevant anymore
 */
/datum/health_scan
	/// Lazyvar, if this is on an atom, this is how far away (tiles) the
	/// `current_user` can be from the `patient` and still get the autorefresh.
	var/track_distance
	/// Do we want to write to `cached_tgui_data` at all?
	/// Turn this off in New() if you're using this with something that
	/// isn't going to want old data. (eg. can't check old scans)
	var/preserve_data
	/// Lazylist, if `preserve_data` is `TRUE` then this gets populated
	/// with the TGUI data from the most recent scan.
	/// Make sure to null this when you're done using it.
	var/list/cached_tgui_data
	/// What owns this scan
	var/datum/scan_source
	/// Active user of this scan
	var/mob/living/carbon/human/current_user
	/// The scan target
	var/mob/living/carbon/human/patient

/datum/health_scan/Destroy(force, ...)
	scan_source = null
	clear_memory(TRUE)
	return ..()

/**
 * Arguments:
 *
 * * `source` - The thing that owns this scan. Can probably be anything, but balloon alerts only work with atoms.
 * * `save_old_scans` - Governs whether the TGUI data from each scan is saved. Disable if it's never going to be used.
 * * `refresh_distance` - How far away the user can be and still get autorefresh. Must set this if you want autorefresh (processing) to work.
 */
/datum/health_scan/New(atom/source, save_old_scans = TRUE, refresh_distance)
	. = ..()
	scan_source = source
	preserve_data = save_old_scans
	track_distance = refresh_distance

/// Sets the user and patient
/datum/health_scan/proc/set_memory(mob/living/carbon/human/next_user, mob/living/carbon/human/next_patient)
	current_user = next_user
	patient = next_patient

/// Nulls the user and patient, also closes the UI if `should_close_ui` is true.
/// Use when the user *or* patient aren't relevant anymore/have changed.
/datum/health_scan/proc/clear_memory(should_close_ui = TRUE)
	current_user = null
	patient = null
	if(should_close_ui)
		SStgui.close_uis(src)

/// Does all the regular checks for trying to scan somebody. Then does `ui_interact` if we can scan them.
/// Returns false if the patient isn't a carbon human, or cannot be scanned.
/// Disable `vocal_checks` if you do not want to warn the user that they can't scan the patient candidate.
/// For best results, the patient should be a carbon human, but works with probably any mob.
/datum/health_scan/proc/attempt_interact(vocal_checks = TRUE, mob/living/carbon/human/new_patient, mob/new_user)
	if(new_patient != patient || new_user != current_user)
		set_memory(new_user, new_patient)
	if(!iscarbon(new_patient))
		if(!istype(scan_source, /atom) || !vocal_checks)
			return FALSE
		new_user.balloon_alert(new_user, "Cannot scan")
		return FALSE
	if(isxeno(new_patient))
		if(!istype(scan_source, /atom) || !vocal_checks)
			return FALSE
		new_user.balloon_alert(new_user, "Unknown entity")
		return FALSE
	if(new_patient.species.species_flags & NO_SCAN)
		if(!istype(scan_source, /atom) || !vocal_checks)
			return FALSE
		new_user.balloon_alert(new_user, "Not Organic")
		return FALSE
	ui_interact(new_user)
	update_static_data(new_user)
	return TRUE

/// Wrapper for checking if there is any reason to process now.
/datum/health_scan/proc/should_process()
	if(!istype(scan_source, /atom) || get_turf(scan_source) != get_turf(current_user) || get_dist(get_turf(current_user), get_turf(patient)) > track_distance || patient == current_user)
		return FALSE

/// Updates the UI for the user. Also goes through a bunch of checks for distance, self-scan, etc.
/// If we have to stop processing, expects that we were using `SSobj` to process.
/datum/health_scan/process()
	if(!should_process())
		STOP_PROCESSING(SSobj, src)
		clear_memory(FALSE)
		return
	update_static_data(current_user)

/datum/health_scan/ui_interact(mob/user, datum/tgui/ui)
	SStgui.close_user_uis(user, scan_source)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MedScanner", "Health Scan")
		ui.open()

/datum/health_scan/ui_state(mob/user)
	return GLOB.not_incapacitated_state

/datum/health_scan/ui_static_data(mob/user)
	var/list/data = list(
		"patient" = patient.name,
		"dead" = (patient.stat == DEAD || HAS_TRAIT(patient, TRAIT_FAKEDEATH)),
		"health" = patient.health,
		"max_health" = patient.maxHealth,
		"crit_threshold" = patient.get_crit_threshold(),
		"dead_threshold" = patient.get_death_threshold(),
		"total_brute" = round(patient.getBruteLoss()),
		"total_burn" = round(patient.getFireLoss()),
		"toxin" = round(patient.getToxLoss()),
		"oxy" = round(patient.getOxyLoss()),
		"clone" = round(patient.getCloneLoss()),

		"blood_type" = patient.blood_type,
		"blood_amount" = patient.blood_volume,

		"hugged" = !!(patient.status_flags & XENO_HOST),

		"species" = patient.species.species_flags & ROBOTIC_LIMBS ? "robot" : "human",

		"scan_timing" = stationTimestamp("hh:mm"),
		HEALTH_SCAN_DATA_OUTDATED_SCAN = FALSE,

		"body_temperature" = "[round(patient.bodytemperature*1.8-459.67, 0.1)] degrees F ([round(patient.bodytemperature-T0C, 0.1)] degrees C)",
		"pulse" = "[patient.get_pulse(GETPULSE_TOOL)] bpm",

		"show_advice" = user.client?.prefs?.health_scan_show_advice,
		"accessible_theme" = user.client?.prefs?.accessible_tgui_themes // accessible themes are handled tgui-side
	)
	data["has_unknown_chemicals"] = FALSE
	var/list/chemicals_lists = list()
	for(var/datum/reagent/reagent AS in patient.reagents.reagent_list)
		if(!reagent.scannable)
			data["has_unknown_chemicals"] = TRUE
			continue
		chemicals_lists["[reagent.name]"] = list(
			"name" = reagent.name,
			"description" = reagent.description,
			"amount" = round(reagent.volume, 0.1),
			"od" = reagent.overdosed,
			"od_threshold" = reagent.overdose_threshold,
			"dangerous" = reagent.overdosed || istype(reagent, /datum/reagent/toxin)
		)
	data["has_chemicals"] = length(patient.reagents.reagent_list)
	data["chemicals_lists"] = chemicals_lists

	if(!ishuman(patient)) // everything after this applies to carbon humans only
		return data

	var/list/limb_data_lists = list()

	var/infection_message
	var/internal_bleeding

	var/unknown_implants = 0
	for(var/datum/limb/limb AS in patient.limbs)
		var/infected = FALSE
		var/necrotized = FALSE

		if(!internal_bleeding)
			for(var/datum/wound/wound in limb.wounds)
				if(!istype(wound, /datum/wound/internal_bleeding))
					continue
				internal_bleeding = TRUE
				break
		if(limb.germ_level > INFECTION_LEVEL_ONE)
			infection_message = "Infection detected in subject's [limb.display_name]. Antibiotics recommended."
			infected = TRUE
		if(limb.limb_status & LIMB_NECROTIZED)
			infection_message = "Subject's [limb.display_name] has necrotized. Surgery required."
			necrotized = TRUE

		if(limb.hidden)
			unknown_implants++
		var/implant = FALSE
		if(length(limb.implants))
			for(var/obj/item/embedded AS in limb.implants)
				if(embedded.is_beneficial_implant())
					continue
				unknown_implants++
				implant = TRUE

		if(!limb.brute_dam && !limb.burn_dam && !CHECK_BITFIELD(limb.limb_status, LIMB_DESTROYED) && !CHECK_BITFIELD(limb.limb_status, LIMB_BROKEN) && !CHECK_BITFIELD(limb.limb_status, LIMB_BLEEDING) && !CHECK_BITFIELD(limb.limb_status, LIMB_NECROTIZED) && !implant && !infected )
			continue
		var/list/current_list = list(
			"name" = limb.display_name,
			"brute" = round(limb.brute_dam),
			"burn" = round(limb.burn_dam),
			"bandaged" = limb.is_bandaged(),
			"salved" = limb.is_salved(),
			"missing" = CHECK_BITFIELD(limb.limb_status, LIMB_DESTROYED),
			"limb_status" = null,
			"limb_type" = null,
			"bleeding" = CHECK_BITFIELD(limb.limb_status, LIMB_BLEEDING),
			"open_incision" = limb.surgery_open_stage,
			"necrotized" = necrotized,
			"infected" = infected,
			"implant" = implant
		)
		var/limb_type = ""
		if(CHECK_BITFIELD(limb.limb_status, LIMB_ROBOT))
			limb_type = "Robotic"
		else if(CHECK_BITFIELD(limb.limb_status, LIMB_BIOTIC))
			limb_type = "Biotic"

		var/limb_status = ""
		if(CHECK_BITFIELD(limb.limb_status, LIMB_BROKEN) && !CHECK_BITFIELD(limb.limb_status, LIMB_STABILIZED) && !CHECK_BITFIELD(limb.limb_status, LIMB_SPLINTED))
			limb_status = "Fracture"
		else if(CHECK_BITFIELD(limb.limb_status, LIMB_STABILIZED))
			limb_status = "Stabilized"
		else if(CHECK_BITFIELD(limb.limb_status, LIMB_SPLINTED))
			limb_status = "Splinted"
		current_list["limb_type"] = limb_type
		current_list["limb_status"] = limb_status
		limb_data_lists["[limb.name]"] = current_list
	data["limb_data_lists"] = limb_data_lists
	data["limbs_damaged"] = length(limb_data_lists)
	data["internal_bleeding"] = internal_bleeding
	data["infection"] = infection_message
	data["implants"] = unknown_implants
	var/damaged_organs = list()
	for(var/datum/internal_organ/organ AS in patient.internal_organs)
		if(organ.organ_status == ORGAN_HEALTHY)
			continue
		var/current_organ = list(
			"name" = organ.name,
			"status" = organ.organ_status == ORGAN_BRUISED ? "Bruised" : "Broken",
			"damage" = organ.damage,
			"effects" = organ.damage_description,
		)
		damaged_organs += list(current_organ)
	data["damaged_organs"] = damaged_organs

	var/organic_patient = !(patient.species.species_flags & (IS_SYNTHETIC|ROBOTIC_LIMBS))
	var/revivable_patient = FALSE

	if(HAS_TRAIT(patient, TRAIT_IMMEDIATE_DEFIB))
		revivable_patient = TRUE
	else if(issynth(patient))
		if(patient.health >= patient.get_death_threshold())
			revivable_patient = TRUE
	else if(patient.health + patient.getOxyLoss() + (DEFIBRILLATOR_HEALING_TIMES_SKILL(user.skills.getRating(SKILL_MEDICAL), DEFIBRILLATOR_BASE_HEALING_VALUE)) >= patient.get_death_threshold())
		revivable_patient = TRUE

	if(HAS_TRAIT(patient, TRAIT_UNDEFIBBABLE))
		data["revivable_string"] = "Permanently deceased" // the actual information shown next to "revivable:" in tgui. "too much damage" etc.
		data["revivable_boolean"] = FALSE // the actual TRUE/FALSE entry used by tgui. if false, revivable text is red. if true, revivable text is yellow
	else if(organic_patient && !patient.has_working_organs())
		data["revivable_string"] = "Not ready to resuscitate - heart too damaged"
		data["revivable_boolean"] = FALSE
	else if(revivable_patient)
		data["revivable_string"] = "Ready to [organic_patient ? "resuscitate" : "reboot"]" // flavor
		data["revivable_boolean"] = TRUE
	else
		data["revivable_string"] = "Not ready to [organic_patient ? "resuscitate" : "reboot"] - repair damage above [patient.get_death_threshold() / patient.maxHealth * 100 - (organic_patient ? (DEFIBRILLATOR_HEALING_TIMES_SKILL(user.skills.getRating(SKILL_MEDICAL), DEFIBRILLATOR_BASE_HEALING_VALUE)) : 0)]%"
		data["revivable_boolean"] = FALSE

	var/list/advice = list()
	var/list/temp_advice = list()
	if(user.client?.prefs?.health_scan_show_advice && !HAS_TRAIT(patient, TRAIT_UNDEFIBBABLE)) // only show advice at all if the patient is coming back
		//random stuff that docs should be aware of. possible todo: make a system so we can put these in a collapsible tgui element if there's more added here.
		if(patient.maxHealth != LIVING_DEFAULT_MAX_HEALTH)
			advice += list(list(
				"advice" = "Patient has [patient.maxHealth / LIVING_DEFAULT_MAX_HEALTH * 100]% constitution.",
				"tooltip" = patient.maxHealth < LIVING_DEFAULT_MAX_HEALTH ? "Patient has less maximum health than most humans." : "Patient has more maximum health than most humans.",
				"icon" = patient.maxHealth < LIVING_DEFAULT_MAX_HEALTH ? "heart-broken" : "heartbeat",
				"color" = patient.maxHealth < LIVING_DEFAULT_MAX_HEALTH ? "grey" : "pink",
				"collapsible" = "Miscellaneous"
			))
		//species advice. possible todo: make a system so we can put these in a collapsible tgui element
		if(issynth(patient)) //specifically checking synth/robot here as these are specific to whichever species
			advice += list(list(
				"advice" = "Synthetic: Patient does not heal on defibrillation.",
				"tooltip" = "Synthetics do not heal when being shocked with a defibrillator, meaning they are only revivable over [patient.get_death_threshold() / patient.maxHealth * 100]% health.",
				"icon" = "robot",
				"color" = "label"
			))
			advice += list(list(
				"advice" = "Synthetic: Patient overheats while lower than [SYNTHETIC_CRIT_THRESHOLD / patient.maxHealth * 100]% health.",
				"tooltip" = "Synthetics overheat rapidly while their health is lower than [SYNTHETIC_CRIT_THRESHOLD / patient.maxHealth * 100]%. When defibrillating, the patient should be repaired above this threshold to avoid unnecessary burning.",
				"icon" = "robot",
				"color" = "label"
			))
			advice += list(list(
				"advice" = "Synthetic: Patient does not suffer from brain-death.",
				"tooltip" = "Synthetics don't expire after 5 minutes of death.",
				"icon" = "robot",
				"color" = "label"
			))
		else if(isrobot(patient))
			advice += list(list(
				"advice" = "Combat Robot: Patient can be immediately defibrillated.",
				"tooltip" = "Combat Robots can be defibrillated regardless of health. It is highly advised to resuscitate them the moment their armor is removed instead of attempting repair.",
				"icon" = "robot",
				"color" = "label"
			))
			advice += list(list(
				"advice" = "Combat Robot: Patient does not enter critical condition.",
				"tooltip" = "Combat Robots do not enter critical condition. They will continue operating until death at [patient.get_death_threshold() / patient.maxHealth * 100]% health.",
				"icon" = "robot",
				"color" = "label"
			))
		if(patient.stat == DEAD) // death advice
			var/dead_color
			switch(patient.dead_ticks)
				if(0 to 0.4 * TIME_BEFORE_DNR)
					dead_color = "yellow"
				if(0.4 * TIME_BEFORE_DNR to 0.8 * TIME_BEFORE_DNR)
					dead_color = "orange"
				if(0.8 * TIME_BEFORE_DNR to INFINITY)
					dead_color = "red"
			if(!issynth(patient)) // specifically checking for synths here because synths don't expire but robots do
				advice += list(list(
					"advice" = "Time remaining to revive: [DisplayTimeText((TIME_BEFORE_DNR-(patient.dead_ticks))*20)].",
					"tooltip" = "This is how long until the patient is permanently unrevivable. Stasis bags pause this timer.",
					"icon" = "clock",
					"color" = dead_color
					))
			if(patient.wear_suit && patient.wear_suit.atom_flags & CONDUCT)
				advice += list(list(
					"advice" = "Remove patient's suit or armor.",
					"tooltip" = "To resuscitate the patient, you need to remove anything conductive obscuring their chest.",
					"icon" = "shield-alt",
					"color" = "blue"
					))
			if(revivable_patient)
				advice += list(list(
					"advice" = "Administer shock via defibrillator!",
					"tooltip" = "The patient is ready to be revived, resuscitate them as soon as possible!",
					"icon" = "bolt",
					"color" = "yellow"
					))
		if(patient.getBruteLoss() > 5)
			if(organic_patient)
				advice += list(list(
					"advice" = "Use trauma kits or sutures to repair the bruised areas.",
					"tooltip" = "Advanced trauma kits will heal brute damage, scaling with how proficient you are in the Medical field. Treated wounds slowly heal on their own.",
					"icon" = "band-aid",
					"color" = "green"
					))
			else
				advice += list(list(
					"advice" = "Use a blowtorch or nanopaste to repair the dented areas.",
					"tooltip" = "Only a blowtorch or nanopaste can repair dented robotic limbs.",
					"icon" = "tools",
					"color" = "red"
				))
		if(patient.getFireLoss() > 5)
			if(organic_patient)
				advice += list(list(
					"advice" = "Use burn kits or sutures to repair the burned areas.",
					"tooltip" = "Advanced burn kits will heal burn damage, scaling with how proficient you are in the Medical field. Treated wounds slowly heal on their own.",
					"icon" = "band-aid",
					"color" = "orange"
					))
			else
				advice += list(list(
					"advice" = "Use cable coils or nanopaste to repair the scorched areas.",
					"tooltip" = "Only cable coils or nanopaste can repair scorched robotic limbs.",
					"icon" = "plug",
					"color" = "orange"
				))
		if(patient.getCloneLoss() > 5)
			advice += list(list(
				"advice" = organic_patient ? "Patient should sleep or seek cryo treatment - cellular damage." : "Patient should seek a robotic cradle - integrity damage.",
				"tooltip" = "[organic_patient ? "Cellular damage" : "Integrity damage"] is sustained from psychic draining, special chemicals and special weapons. It can only be healed through the aforementioned methods.",
				"icon" = organic_patient ? "dna" : "wrench",
				"color" = "teal"
				))
		if(unknown_implants)
			advice += list(list(
				"advice" = "Remove embedded objects with tweezers.",
				"tooltip" = "While moving with embedded objects inside, the patient will randomly sustain Brute damage. Make sure to take some time in between removing large amounts of implants to avoid internal damage.",
				"icon" = "window-close",
				"color" = "red"
				))
		if(organic_patient) // human advice, includes chems
			if(patient.status_flags & XENO_HOST)
				advice += list(list(
					"advice" = "Alien embryo detected. Immediate surgical intervention advised.", // friend detected :)
					"tooltip" = "The patient has been implanted with an alien embryo! Left untreated, it will burst out of their chest. Surgical intervention is strongly advised.",
					"icon" = "exclamation",
					"color" = "red"
					))
			if(internal_bleeding)
				advice += list(list(
					"advice" = "Internal bleeding detected. Cryo treatment advised.",
					"tooltip" = "Alongside cryogenic treatment, Quick Clot Plus can remove internal bleeding, or normal Quick Clot reduces its symptoms.",
					"icon" = "tint",
					"color" = "crimson"
					))
			if(infection_message)
				temp_advice = list(list(
					"advice" = "Administer a single dose of spaceacillin - infections detected.",
					"tooltip" = "There are one or more infections detected. If left untreated, they may worsen into Necrosis and require surgery.",
					"icon" = "biohazard",
					"color" = "olive"
					))
				if(chemicals_lists["Spaceacillin"])
					if(chemicals_lists["Spaceacillin"]["amount"] < 2)
						advice += temp_advice
				else
					advice += temp_advice
			var/datum/internal_organ/brain/brain = patient.get_organ_slot(ORGAN_SLOT_BRAIN)
			if(brain.organ_status != ORGAN_HEALTHY)
				temp_advice = list(list(
					"advice" = "Administer a single dose of alkysine.",
					"tooltip" = "Significant brain damage detected. Alkysine heals brain damage. If left untreated, patient may be unable to function well.",
					"icon" = "syringe",
					"color" = "blue"
					))
				if(chemicals_lists["Alkysine"])
					if(chemicals_lists["Alkysine"]["amount"] < 3)
						advice += temp_advice
				else
					advice += temp_advice
			var/datum/internal_organ/eyes/eyes = patient.get_organ_slot(ORGAN_SLOT_EYES)
			if(eyes.organ_status != ORGAN_HEALTHY)
				temp_advice = list(list(
					"advice" = "Administer a single dose of imidazoline.",
					"tooltip" = "Eye damage detected. Imidazoline heals eye damage. If left untreated, patient may be unable to see properly.",
					"icon" = "syringe",
					"color" = "yellow"
					))
				if(chemicals_lists["Imidazoline"])
					if(chemicals_lists["Imidazoline"]["amount"] < 3)
						advice += temp_advice
				else
					advice += temp_advice
			if(patient.getBruteLoss(organic_only = TRUE) > 30 && !chemicals_lists["Medical nanites"])
				temp_advice = list(list(
					"advice" = "Administer a single dose of bicaridine to reduce physical trauma.",
					"tooltip" = "Significant physical trauma detected. Bicaridine reduces brute damage.",
					"icon" = "syringe",
					"color" = "red"
					))
				if(chemicals_lists["Bicaridine"])
					if(chemicals_lists["Bicaridine"]["amount"] < 3)
						advice += temp_advice
				else
					advice += temp_advice
			if(patient.getFireLoss(organic_only = TRUE) > 30 && !chemicals_lists["Medical nanites"])
				temp_advice = list(list(
					"advice" = "Administer a single dose of kelotane to reduce burns.",
					"tooltip" = "Significant tissue burns detected. Kelotane reduces burn damage.",
					"icon" = "syringe",
					"color" = "yellow"
					))
				if(chemicals_lists["Kelotane"])
					if(chemicals_lists["Kelotane"]["amount"] < 3)
						advice += temp_advice
				else
					advice += temp_advice
			if(patient.getToxLoss() > 15)
				temp_advice = list(list(
					"advice" = "Administer a single dose of dylovene.",
					"tooltip" = "Significant blood toxins detected. Dylovene will reduce toxin damage, or their liver will filter it out on its own. Damaged livers will take even more damage while clearing blood toxins.",
					"icon" = "syringe",
					"color" = "green"
					))
				if(chemicals_lists["Dylovene"])
					if(chemicals_lists["Dylovene"]["amount"] < 5)
						advice += temp_advice
				else
					advice += temp_advice
			if(patient.getOxyLoss() > 30)
				temp_advice = list(list(
					"advice" = "Administer a single dose of dexalin plus to re-oxygenate patient's blood.",
					"tooltip" = "If you don't have Dexalin or Dexalin Plus, CPR or treating their other symptoms and waiting for their bloodstream to re-oxygenate will work.",
					"icon" = "syringe",
					"color" = "blue"
					))
				if(chemicals_lists["Dexalin Plus"])
					if(chemicals_lists["Dexalin Plus"]["amount"] < 3)
						advice += temp_advice
				else
					advice += temp_advice
			if(patient.blood_volume <= 500 && !chemicals_lists["Saline-Glucose"])
				advice += list(list(
					"advice" = "Administer a single dose of Isotonic solution.",
					"tooltip" = "The patient has lost a significant amount of blood. Isotonic solution speeds up blood regeneration significantly.",
					"icon" = "syringe",
					"color" = "cyan"
					))
			if(chemicals_lists["Medical nanites"])
				temp_advice = list(list(
					"advice" = "Nanites detected - only administer Peridaxon Plus, Quickclot and Dylovene.",
					"tooltip" = "Nanites purge all medicines except Peridaxon Plus, Quick Clot/Quick Clot Plus and Dylovene.",
					"icon" = "window-close",
					"color" = "blue"
					))
				advice += temp_advice
			if(patient.stat != DEAD && patient.health < patient.get_crit_threshold())
				temp_advice = list(list(
					"advice" = "Administer a single dose of inaprovaline.",
					"tooltip" = "When used in hard critical condition, Inaprovaline prevents suffocation and heals the patient, triggering a 5 minute cooldown.",
					"icon" = "syringe",
					"color" = "purple"
					))
				if(chemicals_lists["Inaprovaline"])
					if(chemicals_lists["Inaprovaline"]["amount"] < 5)
						advice += temp_advice
				else
					advice += temp_advice
			var/has_pain = FALSE
			if(patient.traumatic_shock > 50)
				has_pain = TRUE

			if(has_pain && !chemicals_lists["Paracetamol"] && !chemicals_lists["Medical nanites"])
				temp_advice = list(list(
					"advice" = "Administer a single dose of tramadol to reduce pain.",
					"tooltip" = "The patient is experiencing performance impeding pain and may suffer symptoms from sluggishness to collapsing. Tramadol reduces pain.",
					"icon" = "syringe",
					"color" = "grey"
					))
				if(chemicals_lists["Tramadol"])
					if(chemicals_lists["Tramadol"]["amount"] < 3)
						advice += temp_advice
				else
					advice += temp_advice

			if(chemicals_lists["Paracetamol"])
				advice += list(list(
					"advice" = "Paracetamol detected - do NOT administer tramadol.",
					"tooltip" = "The patient has Paracetamol in their system. If Tramadol is administered, it will combine with Paracetamol to make Soporific, an anesthetic.",
					"icon" = "window-close",
					"color" = "red"
					))
	else
		advice += list(list(
			"advice" = "Patient is unrevivable.",
			"tooltip" = "The patient is permanently deceased. Can occur through being dead longer than 5 minutes, decapitation, DNR on record, or soullessness.",
			"icon" = "ribbon",
			"color" = "white"
			))
	if(advice.len)
		data["advice"] = advice
	else
		data["advice"] = null

	var/ssd = null
	if(patient.has_brain() && patient.stat != DEAD)
		if(!patient.key)
			ssd = "No soul detected." // Catatonic- NPC, or ghosted
		else if(!patient.client)
			ssd = "Space Sleep Disorder detected." // SSD
	data["ssd"] = ssd

	if(preserve_data)
		cached_tgui_data = data

	return data
