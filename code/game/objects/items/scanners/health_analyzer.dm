GLOBAL_LIST_INIT(known_implants, subtypesof(/obj/item/implant))

/// Bread and butter of medics, scans people when you use it.
/// Most functionality is on `/datum/health_scan`, so go there to change things.
/obj/item/healthanalyzer
	name = "\improper HF2 health analyzer"
	icon = 'icons/obj/device.dmi'
	icon_state = "health"
	worn_icon_list = list(
		slot_l_hand_str = 'icons/mob/inhands/equipment/medical_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/equipment/medical_right.dmi',
	)
	worn_icon_state = "healthanalyzer"
	desc = "A hand-held body scanner able to distinguish vital signs of the subject. The front panel is able to provide the basic readout of the subject's status."
	atom_flags = CONDUCT
	equip_slot_flags = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 5
	throw_range = 10
	///The datum for the health scan behavior
	var/datum/health_scan/scan_datum
	///Prevents `most_recent_scan_data` and `scan_datum.cached_tgui_data` from being populated.
	///Disable if this is something you won't get to use inhand, like an integrated analyzer.
	var/save_scans = TRUE
	///Lazylist: most recent data from `scan_datum.cached_tgui_data`
	var/list/most_recent_scan_data
	///Skill required to bypass the fumble time.
	var/skill_threshold = SKILL_MEDICAL_NOVICE
	///Skill required to have the scanner auto refresh
	var/upper_skill_threshold = SKILL_MEDICAL_NOVICE
	///Distance the current_user can be away from the patient and still get health data.
	///Passed to the `scan_datum` when it's created.
	var/track_distance = HEALTH_ANALYZER_TRACKING_DISTANCE

/obj/item/healthanalyzer/Destroy(force, ...)
	QDEL_NULL(scan_datum)
	return ..()

/obj/item/healthanalyzer/examine(mob/user)
	. = ..()
	. += span_notice("You can set \the [src] to use a more accessible theme in your game preferences.")
	if(save_scans)
		. += span_notice("Use it in hand to see the most recent scan, if it exists.")

/obj/item/healthanalyzer/attack(mob/living/carbon/scan_target, mob/living/user)
	. = ..()
	analyze_vitals(scan_target, user)

/obj/item/healthanalyzer/attack_alternate(mob/living/carbon/scan_target, mob/living/user)
	. = ..()
	analyze_vitals(scan_target, user, TRUE)

/**
 * A wrapper for scanning a target. This way, it is a lot more flexible.
 *
 * * `scan_target` - Person being scanned. Locked to carbon humans.
 * * `user` - User doing the scan.
 * * `show_patient` - If `TRUE`, shows this scan to the `scan_target`. Otheriwse shows it to `user`.
 */
/obj/item/healthanalyzer/proc/analyze_vitals(mob/living/carbon/scan_target, mob/living/user, show_patient)
	if(user.skills.getRating(SKILL_MEDICAL) < skill_threshold)
		to_chat(user, span_warning("You start fumbling around with [src]..."))
		if(!do_after(user, max(SKILL_TASK_AVERAGE - (1 SECONDS * user.skills.getRating(SKILL_MEDICAL)), 0), NONE, scan_target, BUSY_ICON_UNSKILLED))
			return
	playsound(src.loc, 'sound/items/healthanalyzer.ogg', 50)
	if(!scan_datum)
		// if the scan datum doesn't exist yet, we make it
		// this datum will be reused forever until we qdel
		scan_datum = new(src, save_scans, track_distance)
	if(show_patient)
		if(!scan_target.client?.prefs?.health_scan_allow_scan_showing || scan_target.faction != user.faction)
			balloon_alert(user, "Can't show healthscan")
			return
		balloon_alert_to_viewers("Showed healthscan", vision_distance = 4)
		scan_datum.attempt_interact(FALSE, scan_target, scan_target)
	else
		scan_datum.attempt_interact(TRUE, scan_target, user)
	if(save_scans)
		most_recent_scan_data = scan_datum.cached_tgui_data
		most_recent_scan_data[HEALTH_SCAN_DATA_OUTDATED_SCAN] = TRUE
		scan_datum.cached_tgui_data = null
	if(!scan_datum.should_process() || user.skills.getRating(SKILL_MEDICAL) < upper_skill_threshold)
		scan_datum.clear_memory(FALSE)
		return
	START_PROCESSING(SSobj, scan_datum)

/obj/item/healthanalyzer/removed_from_inventory(mob/user)
	. = ..()
	if(get_turf(src) == get_turf(user)) //If you drop it or it enters a bag on the user.
		return
	STOP_PROCESSING(SSobj, scan_datum)

/obj/item/healthanalyzer/attack_self(mob/user)
	. = ..()
	if(!LAZYLEN(most_recent_scan_data))
		to_chat(user, span_warning("No scan data found."))

	ui_interact(user)

/obj/item/healthanalyzer/ui_interact(mob/user, datum/tgui/ui)
	if(!LAZYLEN(most_recent_scan_data))
		return

	SStgui.close_user_uis(user, scan_datum)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MedScanner", "Stored Health Scan")
		ui.open()
		ui.set_autoupdate(FALSE)

/obj/item/healthanalyzer/ui_data(mob/user)
	return most_recent_scan_data
