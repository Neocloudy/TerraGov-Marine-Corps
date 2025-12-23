/// Fires when a human has a different max_health than normal.
/// Like with the species advice, I want to kill this for a better
/// system, but this is also being imported into the new system until then.
/datum/scanner_advice/special_max_health
	priority = ADVICE_PRIORITY_MAX_HEALTH

/datum/scanner_advice/special_max_health/can_show(mob/living/carbon/human/patient, mob/user)
	return (patient.max_health != LIVING_DEFAULT_MAX_HEALTH)

/datum/scanner_advice/special_max_health/get_data(mob/living/carbon/human/patient, mob/user)
	. = list(
		ADVICE_TEXT = "Patient has [patient.max_health / LIVING_DEFAULT_MAX_HEALTH * 100]% constitution.",
		ADVICE_TOOLTIP = patient.max_health < LIVING_DEFAULT_MAX_HEALTH ? "Patient has less maximum health than most humans." : "Patient has more maximum health than most humans.",
		ADVICE_ICON = patient.max_health < LIVING_DEFAULT_MAX_HEALTH ? FA_ICON_FEATHER : FA_ICON_SHIELD_HEART,
		ADVICE_ICON_COLOR = patient.max_health < LIVING_DEFAULT_MAX_HEALTH ? "grey" : "pink",
	)
