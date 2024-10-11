/// Gloves that scan people when you wear them.
/// Most functionality is on `/datum/health_scan`, so go there to change things.
/obj/item/clothing/gloves/healthanalyzer
	name = "\improper HF2 medical gloves"
	desc = "Advanced medical gloves with a built-in analyzer for scanning patients quickly."
	icon_state = "medscan_gloves"
	worn_icon_state = "medscan_gloves"
	siemens_coefficient = 0.50
	soft_armor = list(MELEE = 25, BULLET = 15, LASER = 10, ENERGY = 15, BOMB = 15, BIO = 5, FIRE = 15, ACID = 15)
	cold_protection_flags = HANDS
	heat_protection_flags = HANDS
	min_cold_protection_temperature = GLOVES_MIN_COLD_PROTECTION_TEMPERATURE
	max_heat_protection_temperature = GLOVES_MAX_HEAT_PROTECTION_TEMPERATURE
	/// The datum for the health scan behavior.
	var/datum/health_scan/scan_datum

/obj/item/clothing/gloves/healthanalyzer/Destroy()
	QDEL_NULL(scan_datum)
	return ..()

/obj/item/clothing/gloves/healthanalyzer/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(user.gloves == src)
		RegisterSignal(user, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
		RegisterSignal(user, COMSIG_HUMAN_MELEE_UNARMED_ATTACK_ALTERNATE, PROC_REF(on_unarmed_attack_alternate))
	else
		if(!isnull(scan_datum))
			STOP_PROCESSING(SSobj, scan_datum)
		UnregisterSignal(user, COMSIG_HUMAN_MELEE_UNARMED_ATTACK)
		UnregisterSignal(user, COMSIG_HUMAN_MELEE_UNARMED_ATTACK_ALTERNATE, PROC_REF(on_unarmed_attack_alternate))

/obj/item/clothing/gloves/healthanalyzer/unequipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(!isnull(scan_datum))
		STOP_PROCESSING(SSobj, scan_datum)
	UnregisterSignal(user, COMSIG_HUMAN_MELEE_UNARMED_ATTACK) //Unregisters in the case of getting delimbed
	UnregisterSignal(user, COMSIG_HUMAN_MELEE_UNARMED_ATTACK_ALTERNATE)

/**
 * When you help intent, unarmed attack somebody,
 * tries to scan the person you just clicked on.
 *
 * * `user` - The wearer of the gloves passed to the healthscan datum.
 * * `target` - The target of the scan passed to the healthscan datum.
 */
/obj/item/clothing/gloves/healthanalyzer/proc/on_unarmed_attack(mob/living/carbon/human/user, mob/living/carbon/human/target)
	SIGNAL_HANDLER
	if(user.a_intent != INTENT_HELP)
		return
	if(!istype(user) || !istype(target))
		return
	if(!scan_datum)
		scan_datum = new(src, FALSE, HEALTH_ANALYZER_TRACKING_DISTANCE)
	playsound(src.loc, 'sound/items/healthanalyzer.ogg', 50)
	INVOKE_ASYNC(scan_datum, TYPE_PROC_REF(/datum/health_scan, attempt_interact), TRUE, target, user)
	if(scan_datum.should_process())
		START_PROCESSING(SSobj, scan_datum)

/**
 * Same as `on_unarmed_attack` but attempts to show the patient the scan.
 *
 * * `user` - The wearer of the gloves passed to the healthscan datum.
 * * `target` - The target of the scan passed to the healthscan datum.
 */
/obj/item/clothing/gloves/healthanalyzer/proc/on_unarmed_attack_alternate(mob/living/carbon/human/user, mob/living/carbon/human/target)
	SIGNAL_HANDLER
	if(!target.client?.prefs?.health_scan_allow_scan_showing || scan_target.faction != user.faction)
		balloon_alert(user, "Can't show healthscan")
		return
	if(user.a_intent != INTENT_HELP)
		return
	if(!istype(user) || !istype(target))
		return
	if(!scan_datum)
		scan_datum = new(src, FALSE, null)
	playsound(src.loc, 'sound/items/healthanalyzer.ogg', 50)
	INVOKE_ASYNC(scan_datum, TYPE_PROC_REF(/datum/health_scan, attempt_interact), FALSE, target, target)
