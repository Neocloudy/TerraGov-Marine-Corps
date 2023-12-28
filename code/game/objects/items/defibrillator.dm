/*
///////////////////Defibrillators///////////////////
* Defibrillators have changed and will now require that both brute and burn are 179 or under for successful defibrillation.
* For example, if the patient has 179 brute, 179 burn, and maximum oxyloss or toxin, they will get massive healing to reach -52 health.
* If a patient is missing any damage levels, oxygen damage will be dealt so they are in critical condition.
* If the patient has more than 180 of either brute or burn, the defibrillation will fail and they will heal 12 brute, burn and clone.
*/

#define TISSUE_DAMAGE_HEAL 12
#define DOAFTER_FAIL_STRING "Take [src]'s paddles back out to continue."
#define FAIL_REASON_TISSUE "Vital signs are weak. Repair damage and try again."
#define FAIL_REASON_ORGANS "Patient's organs are too damaged to sustain life. Surgical intervention required."
#define FAIL_REASON_DECAPITATED "Patient is missing their head."
#define FAIL_REASON_BRAINDEAD "Patient is braindead. Further attempts futile."
#define FAIL_REASON_DNR "Patient is missing intelligence patterns or has a DNR. Further attempts futile."
#define FAIL_REASON_SOUL "No soul detected. Please try again."

/obj/item/defibrillator
	name = "emergency defibrillator"
	desc = "A handheld emergency defibrillator, used to resuscitate patients."
	icon = 'icons/obj/items/defibrillator.dmi'
	icon_state = "defib_full"
	item_state = "defib"
	flags_atom = CONDUCT
	flags_item = NOBLUDGEON
	flags_equip_slot = ITEM_SLOT_BELT
	force = 5
	throwforce = 6
	w_class = WEIGHT_CLASS_NORMAL

	var/ready = FALSE
	///wether readying is needed
	var/ready_needed = TRUE
	var/damage_threshold = 12 // maximum brute, burn defibs will heal.
	var/charge_cost = 66 // how much charge is used when defibbing, with this allows 15 uses
	var/obj/item/cell/dcell = null
	var/datum/effect_system/spark_spread/sparks
	var/defib_cooldown = 0 //Cooldown for toggling the defib


/obj/item/defibrillator/suicide_act(mob/user)
	user.visible_message(span_danger("[user] is putting the live paddles on [user.p_their()] chest! It looks like [user.p_theyre()] trying to commit suicide."))
	return (FIRELOSS)


/obj/item/defibrillator/Initialize(mapload)
	. = ..()
	sparks = new
	sparks.set_up(5, 0, src)
	sparks.attach(src)
	set_dcell(new /obj/item/cell/defibrillator())
	update_icon()


/obj/item/defibrillator/Destroy()
	QDEL_NULL(sparks)
	if(dcell)
		UnregisterSignal(dcell, COMSIG_QDELETING)
		QDEL_NULL(dcell)
	return ..()


/obj/item/defibrillator/update_icon_state()
	icon_state = "defib"
	if(ready)
		icon_state += "_out"
	if(dcell?.charge)
		switch(round(dcell.charge * 100 / dcell.maxcharge))
			if(67 to INFINITY)
				icon_state += "_full"
			if(34 to 66)
				icon_state += "_half"
			if(1 to 33)
				icon_state += "_low"
	else
		icon_state += "_empty"


/obj/item/defibrillator/examine(mob/user)
	. = ..()
	. += maybe_message_recharge_hint()


/**
 * Message user with a hint to recharge defibrillator
 * and how to do it if the battery is low.
*/
/obj/item/defibrillator/proc/maybe_message_recharge_hint(mob/living/carbon/human/user)
	if(!dcell)
		return

	var/message
	if(dcell.charge < charge_cost)
		message = "The battery is empty."
	else if(round(dcell.charge * 100 / dcell.maxcharge) <= 33)
		message = "The battery is low."

	if(!message)
		return
	return span_notice("[message] You can click-drag defibrillator on corpsman backpack to recharge it.")


/obj/item/defibrillator/attack_self(mob/living/carbon/human/user)
	if(!ready_needed)
		return
	if(!istype(user))
		return
	if(defib_cooldown > world.time)
		return

	//Job knowledge requirement
	var/skill = user.skills.getRating(SKILL_MEDICAL)
	if(skill < SKILL_MEDICAL_PRACTICED)
		user.visible_message(span_notice("[user] fumbles around figuring out how to use [src]."),
		span_notice("You fumble around figuring out how to use [src]."))
		if(!do_after(user, SKILL_TASK_AVERAGE - (SKILL_TASK_VERY_EASY * skill), NONE, src, BUSY_ICON_UNSKILLED)) // 3 seconds with medical skill, 5 without
			return

	defib_cooldown = world.time + 0.6 SECONDS
	ready = !ready
	user.visible_message(span_notice("[user] turns [src] [ready? "on and opens the cover" : "off and closes the cover"]."),
	span_notice("You turn [src] [ready? "on and open the cover" : "off and close the cover"]."))
	playsound(get_turf(src), "sparks", 25, TRUE, 4)
	if(ready)
		w_class = WEIGHT_CLASS_BULKY // Let's not asspull a million fully charged defibs.
		playsound(get_turf(src), 'sound/items/defib_safetyOn.ogg', 30, 0)
	else
		w_class = initial(w_class)
		playsound(get_turf(src), 'sound/items/defib_safetyOff.ogg', 30, 0)
	update_icon()


///Wrapper to guarantee powercells are properly nulled and avoid hard deletes.
/obj/item/defibrillator/proc/set_dcell(obj/item/cell/new_cell)
	if(dcell)
		UnregisterSignal(dcell, COMSIG_QDELETING)
	dcell = new_cell
	if(dcell)
		RegisterSignal(dcell, COMSIG_QDELETING, PROC_REF(on_cell_deletion))


///Called by the deletion of the referenced powercell.
/obj/item/defibrillator/proc/on_cell_deletion(obj/item/cell/source, force)
	SIGNAL_HANDLER
	stack_trace("Powercell deleted while powering the defib, this isn't supposed to happen normally.")
	set_dcell(null)

/mob/living/proc/get_ghost()
	if(client) //Let's call up the correct ghost!
		return null
	for(var/mob/dead/observer/ghost AS in GLOB.observer_list)
		if(!ghost) //Observers hard del often so lets just be safe
			continue
		if(isnull(ghost.can_reenter_corpse))
			continue
		if(ghost.can_reenter_corpse.resolve() != src)
			continue
		if(ghost.client)
			return ghost
	return null

/mob/living/carbon/human/proc/has_working_organs()
	var/datum/internal_organ/heart/heart = internal_organs_by_name["heart"]

	if(!heart || heart.organ_status == ORGAN_BROKEN || !has_brain())
		return FALSE

	return TRUE

/obj/item/defibrillator/attack(mob/living/carbon/human/H, mob/living/carbon/human/user)
	defibrillate(H,user)

///Split proc that actually does the defibrillation. Separated to be used more easily by medical gloves
/obj/item/defibrillator/proc/defibrillate(mob/living/carbon/human/H, mob/living/carbon/human/user)
	if(user.do_actions) //Currently doing something
		user.visible_message(span_warning("You're already doing something!"))
		return

	if(defib_cooldown > world.time) // defibrillator cooldown, trying to keep this low
		user.visible_message(span_warning("The defibrillator is on cooldown, wait a second!"))
		return

	defib_cooldown = world.time + 0.6 SECONDS

	var/defib_heal_amt = damage_threshold

	//job knowledge requirement
	var/skill = user.skills.getRating(SKILL_MEDICAL)
	if(skill < SKILL_MEDICAL_PRACTICED)
		user.visible_message(span_notice("[user] fumbles around figuring out how to use [src]."),
		span_notice("You fumble around figuring out how to use [src]."))
		var/fumbling_time = SKILL_TASK_EASY - (SKILL_TASK_VERY_EASY * skill) // since defibs become bulky when active, let's make this more bearable
		if(!do_after(user, fumbling_time, NONE, H, BUSY_ICON_UNSKILLED))
			return
	else
		defib_heal_amt *= skill * 0.5 //more healing power when used by a doctor (this means non-trained don't heal)

	if(!ishuman(H))
		to_chat(user, span_warning("You can't defibrilate [H]. You don't even know where to put the paddles!"))
		return
	if(!ready)
		to_chat(user, span_warning("Take [src]'s paddles out first."))
		return
	if(dcell.charge <= charge_cost)
		user.visible_message(span_warning("[icon2html(src, viewers(user))] \The [src] buzzes: Internal battery depleted, seek recharger. Cannot analyze nor administer shock."))
		to_chat(user, maybe_message_recharge_hint())
		return

	var/mob/dead/observer/G = H.get_ghost()
	if(G)
		notify_ghost(G, "<font size=4><b>Your heart is being defibrillated!</b></font>", ghost_sound = 'sound/effects/gladosmarinerevive.ogg')
		G.reenter_corpse()

	user.visible_message(span_notice("[user] starts setting up the paddles on [H]'s chest."),
	span_notice("You start setting up the paddles on [H]'s chest."))

	if(do_after(user, 3 SECONDS, NONE, H, BUSY_ICON_FRIENDLY, BUSY_ICON_MEDICAL))
		playsound(get_turf(src),'sound/items/defib_charge.ogg', 25, 0) // Do not vary, it should be precisely 3 seconds
		user.visible_message(span_notice("[user] starts charging the paddles on [H]'s chest."),
		span_notice("You start charging the paddles on [H]'s chest."))
		if(!ready)
			to_chat(user, span_warning(DOAFTER_FAIL_STRING))
			return

		if(do_after(user, 2 SECONDS, NONE, H, BUSY_ICON_FRIENDLY, BUSY_ICON_MEDICAL)) // 5 seconds revive time
			if(!ready)
				to_chat(user, span_warning(DOAFTER_FAIL_STRING))
				return

			if(H.stat == DEAD && H.wear_suit && H.wear_suit.flags_atom & CONDUCT) // Dead, but chest obscured.
				user.visible_message(span_warning("[icon2html(src, viewers(user))] \The [src] buzzes: Patient's chest is obscured, operation aborted. Remove suit or armor and try again."))
				playsound(src, 'sound/items/defib_failed.ogg', 40, FALSE)
				return

			else if(H.stat != DEAD) // they aren't even dead lol
				user.visible_message(span_warning("[icon2html(src, viewers(user))] \The [src] buzzes: Patient is not in a valid state. Operation aborted."))
				playsound(src, 'sound/items/defib_failed.ogg', 40, FALSE)
				return

			else // Actual defibrillation, since we can't figure out another reason to not try

				sparks.start()
				H.visible_message(span_warning("[H]'s body convulses a bit."))
				playsound(src, 'sound/items/defib_zap.ogg', 60, FALSE)//, -1)
				dcell.use(charge_cost)
				update_icon()
				H.updatehealth()

				var/defib_result = H.check_defib()
				var/fail_reason

				switch (defib_result)
					if (DEFIB_FAIL_TISSUE_DAMAGE) // checks damage threshold in human_defines.dm, whatever is defined for their species
						fail_reason = FAIL_REASON_TISSUE // also, if this is the fail reason, heals brute&burn
					if (DEFIB_FAIL_BAD_ORGANS)
						fail_reason = FAIL_REASON_ORGANS
					if (DEFIB_FAIL_DECAPITATED)
						if (H.species.species_flags & DETACHABLE_HEAD) // special message for synths/crobots missing their head
							fail_reason = "Patient is missing their head. Reattach and try again."
						else
							fail_reason = FAIL_REASON_DECAPITATED
					if (DEFIB_FAIL_BRAINDEAD)
						fail_reason = FAIL_REASON_BRAINDEAD
					if (DEFIB_FAIL_CLIENT_MISSING)
						if(H.mind && !H.client) // No client, like a DNR mob
							fail_reason = FAIL_REASON_DNR
						else if (HAS_TRAIT(H, TRAIT_UNDEFIBBABLE))
							fail_reason = FAIL_REASON_DNR
						else
							fail_reason = FAIL_REASON_SOUL // deadheads that exit their body *after* defib starts

				if(fail_reason) // Defibrillation failed
					user.visible_message(span_warning("[icon2html(src, viewers(user))] \The [src] buzzes: Defibrillation failed - [fail_reason]"))
					playsound(src, 'sound/items/defib_failed.ogg', 50, FALSE)
					if(!issynth(H) && fail_reason == FAIL_REASON_TISSUE) // if too much damage is causing this to fail, heal them
						H.adjustBruteLoss(-defib_heal_amt)
						H.adjustFireLoss(-defib_heal_amt)
						H.updatehealth() // cleanup

				else // No fail reason, let's assume it worked.

					if(HAS_TRAIT(H, TRAIT_IMMEDIATE_DEFIB)) // if they're a robot or something, heal them to one hit from death
						H.setOxyLoss(0)
						H.updatehealth()

						var/heal_target = H.get_death_threshold() - H.health + 1
						var/all_loss = H.getBruteLoss() + H.getFireLoss() + H.getToxLoss()
						if(all_loss && (heal_target > 0))
							var/brute_ratio = H.getBruteLoss() / all_loss
							var/burn_ratio = H.getFireLoss() / all_loss
							var/tox_ratio = H.getToxLoss() / all_loss
							if(tox_ratio)
								H.adjustToxLoss(-(tox_ratio * heal_target))
							H.heal_overall_damage(brute_ratio*heal_target, burn_ratio*heal_target, TRUE) // explicitly also heals robot parts

						user.visible_message(span_notice("[icon2html(src, viewers(user))] \The [src] beeps: Robot reactivation successful."))
						to_chat(H, span_notice("<i><font size=4>You suddenly feel a spark and your central power system reboots, dragging you back to the mortal plane...</font></i>"))
						playsound(get_turf(src), 'sound/items/defib_success.ogg', 50, 0)
						// TODO make this a fucking proc
						H.updatehealth()
						H.set_stat(UNCONSCIOUS)
						H.Unconscious(13 SECONDS)
						H.chestburst = 0
						H.regenerate_icons()
						H.reload_fullscreens()
						H.flash_act()
						H.apply_effect(10, EYE_BLUR)
						H.apply_effect(20 SECONDS, PARALYZE)
						REMOVE_TRAIT(H, TRAIT_PSY_DRAINED, TRAIT_PSY_DRAINED)
						if(user.client)
							var/datum/personal_statistics/personal_statistics = GLOB.personal_statistics_list[user.ckey]
							personal_statistics.revives++
						GLOB.round_statistics.total_human_revives[H.faction]++
						SSblackbox.record_feedback("tally", "round_statistics", 1, "total_human_revives[H.faction]")

						if(CHECK_BITFIELD(H.status_flags, XENO_HOST))
							var/obj/item/alien_embryo/friend = locate() in H
							START_PROCESSING(SSobj, friend)

						notify_ghosts("<b>[user]</b> has brought <b>[H.name]</b> back to life!", source = H, action = NOTIFY_ORBIT)

					else // Humans, doesn't do anything for synths because they're stupid
						// healing target is -52 health
						var/death_threshold = H.get_death_threshold()
						var/crit_threshold = 0

						var/hardcrit_target = crit_threshold + death_threshold * 0.50

						var/total_brute = H.getBruteLoss()
						var/total_burn = H.getFireLoss()

						H.adjustStaminaLoss(-250) // So stamina victims don't come back to life and immediately die

						if (H.health > hardcrit_target)
							H.adjustOxyLoss(H.health - hardcrit_target + 2) // You're not getting up that easy.
						else
							var/overall_damage = total_brute + total_burn + H.getToxLoss() + H.getOxyLoss() + H.getCloneLoss()
							var/mobhealth = H.health
							H.adjustCloneLoss((mobhealth - hardcrit_target) * (H.getCloneLoss() / overall_damage)) // Cleanup so you aren't in hell
							H.adjustOxyLoss((mobhealth - hardcrit_target) * (H.getOxyLoss() / overall_damage) + 2) // just enough to remain in crit
							H.adjustToxLoss((mobhealth - hardcrit_target) * (H.getToxLoss() / overall_damage))
							H.adjustFireLoss((mobhealth - hardcrit_target) * (total_burn / overall_damage))
							H.adjustBruteLoss((mobhealth - hardcrit_target) * (total_brute / overall_damage))
							H.Unconscious(22.5 SECONDS)

						// TODO make this a fucking proc
						H.updatehealth() // adjust procs won't actually update health, let's do some cleanup BEFORE they die instantly
						user.visible_message(span_notice("[icon2html(src, viewers(user))] \The [src] beeps: Resuscitation successful."))
						to_chat(H, span_notice("<i><font size=4>You suddenly feel a spark and your consciousness returns, dragging you back to the mortal plane...</font></i>"))
						H.set_stat(UNCONSCIOUS) // time for a smoke
						H.emote("gasp")
						H.chestburst = 0
						H.regenerate_icons()
						H.reload_fullscreens()
						H.flash_act()
						H.apply_effect(10, EYE_BLUR)
						H.apply_effect(20 SECONDS, PARALYZE)
						H.handle_regular_hud_updates()
						H.dead_ticks = 0 //We reset the DNR time
						playsound(get_turf(src), 'sound/items/defib_success.ogg', 50, 0)
						H.updatehealth() // one last time not sure if this is needed
						REMOVE_TRAIT(H, TRAIT_PSY_DRAINED, TRAIT_PSY_DRAINED)
						if(user.client)
							var/datum/personal_statistics/personal_statistics = GLOB.personal_statistics_list[user.ckey]
							personal_statistics.revives++
						GLOB.round_statistics.total_human_revives[H.faction]++
						SSblackbox.record_feedback("tally", "round_statistics", 1, "total_human_revives[H.faction]")

						if(CHECK_BITFIELD(H.status_flags, XENO_HOST))
							var/obj/item/alien_embryo/friend = locate() in H
							START_PROCESSING(SSobj, friend)

						notify_ghosts("<b>[user]</b> has brought <b>[H.name]</b> back to life!", source = H, action = NOTIFY_ORBIT)

/obj/item/defibrillator/civi
	name = "emergency defibrillator"
	desc = "A handheld emergency defibrillator, used to restore fibrillating patients. Can optionally bring people back from the dead. Appears to be a civillian model."
	icon_state = "civ_defib_full"
	item_state = "defib"


/obj/item/defibrillator/gloves
	name = "advanced medical combat gloves"
	desc = "Advanced medical gloves, these include small electrodes to defibrilate a patiant. No more bulky units!"
	icon_state = "defib_gloves"
	item_state = "defib_gloves"
	ready = TRUE
	ready_needed = FALSE
	flags_equip_slot = ITEM_SLOT_GLOVES
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/obj/clothing/gloves.dmi'
	item_state_worn = TRUE
	siemens_coefficient = 0.50
	blood_sprite_state = "bloodyhands"
	flags_armor_protection = HANDS
	flags_equip_slot = ITEM_SLOT_GLOVES
	attack_verb = "zaps"
	soft_armor = list(MELEE = 25, BULLET = 15, LASER = 10, ENERGY = 15, BOMB = 15, BIO = 5, FIRE = 15, ACID = 15)
	flags_cold_protection = HANDS
	flags_heat_protection = HANDS
	min_cold_protection_temperature = GLOVES_MIN_COLD_PROTECTION_TEMPERATURE
	max_heat_protection_temperature = GLOVES_MAX_HEAT_PROTECTION_TEMPERATURE

/obj/item/defibrillator/gloves/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(user.gloves == src)
		RegisterSignal(user, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	else
		UnregisterSignal(user, COMSIG_HUMAN_MELEE_UNARMED_ATTACK)

/obj/item/defibrillator/gloves/unequipped(mob/living/carbon/human/user, slot)
	. = ..()
	UnregisterSignal(user, COMSIG_HUMAN_MELEE_UNARMED_ATTACK) //Unregisters in the case of getting delimbed

//when you are wearing these gloves, this will call the normal attack code to begin defibing the target
/obj/item/defibrillator/gloves/proc/on_unarmed_attack(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user.a_intent != INTENT_HELP)
		return
	if(istype(user) && istype(target))
		defibrillate(target, user)

/obj/item/defibrillator/gloves/update_icon_state()
	return

