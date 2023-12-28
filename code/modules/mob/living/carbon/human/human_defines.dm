/mob/living/carbon/human
	name = "unknown"
	real_name = "unknown"
	icon = 'icons/mob/human.dmi'
	icon_state = "body_m_s"
	blocks_emissive = EMISSIVE_BLOCK_NONE
	hud_possible = list(HEALTH_HUD, STATUS_HUD_SIMPLE, STATUS_HUD, XENO_EMBRYO_HUD, XENO_REAGENT_HUD, WANTED_HUD, SQUAD_HUD_TERRAGOV, SQUAD_HUD_SOM, ORDER_HUD, PAIN_HUD, XENO_DEBUFF_HUD, HEART_STATUS_HUD)
	health_threshold_crit = -50
	melee_damage = 5
	m_intent = MOVE_INTENT_WALK
	buckle_flags = CAN_BE_BUCKLED|CAN_BUCKLE
	resistance_flags = XENO_DAMAGEABLE|PORTAL_IMMUNE
	appearance_flags = KEEP_TOGETHER|TILE_BOUND|PIXEL_SCALE|LONG_GLIDE

	hud_type = /datum/hud/human

	//Hair colour and style
	var/r_hair = 0
	var/g_hair = 0
	var/b_hair = 0
	var/h_style = "Crewcut"

	// Gradient color and style
	var/r_grad = 0
	var/g_grad = 0
	var/b_grad = 0
	var/grad_style = "None"

	//Facial hair colour and style
	var/r_facial = 0
	var/g_facial = 0
	var/b_facial = 0
	var/f_style = "Shaved"

	//Eye colour
	var/r_eyes = 0
	var/g_eyes = 0
	var/b_eyes = 0

	var/ethnicity = "Western"	// Ethnicity
	var/species_type = ""

	//Skin colour
	var/r_skin = 0
	var/g_skin = 0
	var/b_skin = 0

	//Species specific
	var/moth_wings = "Plain"

	var/lip_style		//no lipstick by default- arguably misleading, as it could be used for general makeup

	var/age = 30		//Player's age (pure fluff)
	var/b_type = "A+"	//Player's bloodtype

	var/underwear = 1	//Which underwear the player wants
	var/undershirt = 0	//Which undershirt the player wants.

	// General information
	var/citizenship = ""
	var/religion = ""

	//Equipment slots
	var/obj/item/wear_suit = null
	var/obj/item/clothing/under/w_uniform = null
	var/obj/item/clothing/shoes/shoes = null
	var/obj/item/belt = null
	var/obj/item/clothing/gloves/gloves = null
	var/obj/item/clothing/glasses/glasses = null
	var/obj/item/head = null
	var/obj/item/wear_ear = null
	var/obj/item/card/id/wear_id = null
	var/obj/item/r_store = null
	var/obj/item/l_store = null
	var/obj/item/s_store = null

	var/icon/stand_icon = null

	var/special_voice = "" // For changing our voice. Used by a symptom.

	var/last_dam = -1	//Used for determining if we need to process all limbs or just some or even none.

	var/mob/remoteview_target

	var/flavor_text = ""
	var/med_record = ""
	var/sec_record = ""
	var/gen_record = ""
	var/exploit_record = ""


	//Life variables

	///How long the human is dead, in life ticks, which is 2 seconds
	var/dead_ticks = 0

	// Brute Revive Threshold with a defibrillator
	var/brute_revive_threshold = 180
	// Burn Revive Threshold with a defibrillator
	var/burn_revive_threshold = 180

	var/holo_card_color = "" //which color type of holocard is printed on us

	var/list/limbs = list()
	var/list/internal_organs_by_name = list() // so internal organs have less ickiness too
	///How much dirt the mob's accumulated. Harmless by itself, but can trigger issues with open wounds or surgery.
	var/germ_level = 0

	///Auras we can create, used for the order choice UI.
	var/static/list/command_aura_allowed = list(AURA_HUMAN_MOVE, AURA_HUMAN_HOLD, AURA_HUMAN_FOCUS)
	///Whether we can use another command order yet. Either null or a timer ID.
	var/command_aura_cooldown

	var/mobility_aura = 0
	var/protection_aura = 0
	var/marksman_aura = 0

	var/datum/squad/assigned_squad //the squad assigned to

	var/cloaking = FALSE

	var/image/SL_directional = null

	var/damageoverlaytemp = 0

	var/specset //Simple way to track which set has the player taken

	var/static/list/can_ride_typecache = typecacheof(list(/mob/living/carbon/human, /mob/living/simple_animal/parrot))

	///Amount of deciseconds gained from the braindeath timer, usually by CPR.
	var/revive_grace_time = 0

	COOLDOWN_DECLARE(xeno_push_delay)

	/// This is the cooldown on suffering additional effects for when shock gets high
	COOLDOWN_DECLARE(last_shock_effect)

///copies over clothing preferences like underwear to another human
/mob/living/carbon/human/proc/copy_clothing_prefs(mob/living/carbon/human/destination)
	destination.underwear = underwear
	destination.undershirt = undershirt

///Checks brute/fire damage, heart status, having a head, death ticks and client for defibrillation
/mob/living/carbon/human/proc/check_defib()

	// Humans must have their brute and burn at 179, it doesn't matter if other damage types are present.
	// They will always be healed to -52% health.
	// Also, robots have their brute and burn thresholds set very high, this won't affect them.
	if((getBruteLoss() >= brute_revive_threshold) || (getFireLoss() >= burn_revive_threshold))
		return DEFIB_FAIL_TISSUE_DAMAGE

	if(!has_working_organs() && !(species.species_flags & ROBOTIC_LIMBS)) // Ya organs dpmt wprl
		return DEFIB_FAIL_BAD_ORGANS

	var/datum/limb/head/head = src.get_limb("head")
	if(head.limb_status & LIMB_DESTROYED)
		return DEFIB_FAIL_DECAPITATED

	if((dead_ticks > TIME_BEFORE_DNR) && !issynth(src)) // synthetics never expire
		return DEFIB_FAIL_BRAINDEAD

	if(!src.client) // no client at all
		return DEFIB_FAIL_CLIENT_MISSING

	return DEFIB_POSSIBLE
