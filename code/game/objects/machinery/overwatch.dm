#define OW_MAIN 0
#define OW_MONITOR 1

#define HIDE_NONE 0
#define HIDE_ON_GROUND 1
#define HIDE_ON_SHIP 2

#define SPOTLIGHT_COOLDOWN_DURATION 6 MINUTES
#define SPOTLIGHT_DURATION 2 MINUTES


#define MESSAGE_SINGLE "Message this marine"
#define ASL "Set or un-set as aSL"
#define SWITCH_SQUAD "Switch this marine's squad"

#define MARK_LASE "Mark this lase on minimap"
#define FIRE_LASE "!!FIRE OB!!"

#define ORBITAL_SPOTLIGHT "Shine orbital spotlight"
#define MESSAGE_NEAR "Message all nearby marines"
#define SQUAD_ACTIONS "Open squad actions menu"

#define MESSAGE_SQUAD "Message all marines in a squad"
#define SWITCH_SQUAD_NEAR "Move all nearby marines to a squad"


GLOBAL_LIST_EMPTY(active_orbital_beacons)
GLOBAL_LIST_EMPTY(active_laser_targets)
GLOBAL_LIST_EMPTY(active_cas_targets)
/obj/machinery/computer/camera_advanced/overwatch
	name = "Overwatch Console"
	desc = "State of the art machinery for giving orders to a squad. <b>Shift click</b> to send order when watching squads."
	density = FALSE
	icon_state = "overwatch"
	screen_overlay = "overwatch_screen"
	req_access = list(ACCESS_MARINE_BRIDGE)
	networks = list("marine")
	open_prompt = FALSE
	interaction_flags = INTERACT_MACHINE_DEFAULT
	var/state = OW_MAIN
	var/living_marines_sorting = FALSE
	///The overwatch computer is busy launching an OB/SB, lock controls
	var/busy = FALSE
	///whether or not we show the dead marines in the squad.
	var/dead_hidden = FALSE
	///which z level is ignored when showing marines.
	var/z_hidden = 0
	/// The faction that this computer can overwatch
	var/faction = FACTION_TERRAGOV
	/// The list of all squads that can be watched
	var/list/watchable_squads

	///Squad being currently overseen
	var/datum/squad/current_squad = null
	///Selected target for bombarding
	var/obj/selected_target
	///Selected order to give to marine
	var/datum/action/innate/order/current_order
	///datum used when sending an attack order
	var/datum/action/innate/order/attack_order/send_attack_order
	///datum used when sending a retreat order
	var/datum/action/innate/order/retreat_order/send_retreat_order
	///datum used when sending a defend order
	var/datum/action/innate/order/defend_order/send_defend_order
	///datum used when sending a rally order
	var/datum/action/innate/order/rally_order/send_rally_order
	///Groundside minimap for overwatch
	var/datum/action/minimap/marine/external/cic_mini
	///Overrides the minimap action minimap and marker flags
	var/map_flags = MINIMAP_FLAG_MARINE
	///Ref of the lase that's had an OB warning mark placed on the minimap
	var/obj/effect/overlay/temp/laser_target/ob/marked_lase
	///Static list of CIC radial options for the camera when clicking on a marine
	var/static/list/human_radial_options = list(
		MESSAGE_SINGLE = image(icon = 'icons/mob/radial.dmi', icon_state = "cic_message_single"),
		ASL = image(icon = 'icons/mob/radial.dmi', icon_state = "cic_asl"),
		SWITCH_SQUAD = image(icon = 'icons/mob/radial.dmi', icon_state = "cic_switch_squad"),
	)
	///Static list of CIC radial options for the camera when clicking on an OB marker
	var/static/list/bombardment_radial_options = list(
		MARK_LASE = image(icon = 'icons/mob/radial.dmi', icon_state = "cic_mark_ob"),
		FIRE_LASE = image(icon = 'icons/mob/radial.dmi', icon_state = "cic_fire_ob"),
	)
	///Static list of CIC radial options for the camera when clicking on a turf
	var/static/list/turf_radial_options = list(
		ORBITAL_SPOTLIGHT = image(icon = 'icons/mob/radial.dmi', icon_state = "cic_orbital_spotlight"),
		MESSAGE_NEAR = image(icon = 'icons/mob/radial.dmi', icon_state = "cic_message_near"),
		SQUAD_ACTIONS =  image(icon = 'icons/mob/radial.dmi', icon_state = "cic_squad_actions"),
	)
	///Static list of CIC radial options for the camera when having clicked on a turf and selected Squad Actions
	var/static/list/squad_radial_options = list(
		MESSAGE_SQUAD = image(icon = 'icons/mob/radial.dmi', icon_state = "cic_message_near"),
		SWITCH_SQUAD_NEAR = image(icon = 'icons/mob/radial.dmi', icon_state = "cic_switch_squad_near"),
	)

/obj/machinery/computer/camera_advanced/overwatch/Initialize(mapload)
	. = ..()
	send_attack_order = new
	send_defend_order = new
	send_retreat_order = new
	send_rally_order = new
	cic_mini = new(null, map_flags, map_flags)
	GLOB.main_overwatch_consoles += src

/obj/machinery/computer/camera_advanced/overwatch/Destroy()
	QDEL_NULL(send_attack_order)
	QDEL_NULL(send_defend_order)
	QDEL_NULL(send_retreat_order)
	QDEL_NULL(send_rally_order)
	QDEL_NULL(cic_mini)
	GLOB.main_overwatch_consoles -= src
	current_order = null
	selected_target = null
	current_squad = null
	marked_lase = null
	return ..()

/obj/machinery/computer/camera_advanced/overwatch/give_actions(mob/living/user)
	. = ..()
	if(send_attack_order)
		send_attack_order.target = user
		send_attack_order.give_action(user)
		actions += send_attack_order
	if(send_defend_order)
		send_defend_order.target = user
		send_defend_order.give_action(user)
		actions += send_defend_order
	if(send_retreat_order)
		send_retreat_order.target = user
		send_retreat_order.give_action(user)
		actions += send_retreat_order
	if(send_rally_order)
		send_rally_order.target = user
		send_rally_order.give_action(user)
		actions += send_rally_order
	if(cic_mini)
		cic_mini.target = user
		cic_mini.give_action(user)
		actions += cic_mini

/obj/machinery/computer/camera_advanced/overwatch/main
	icon_state = "overwatch_main"
	screen_overlay = "overwatch_main_screen"
	name = "Main Overwatch Console"
	desc = "State of the art machinery for general overwatch purposes."

/obj/machinery/computer/camera_advanced/overwatch/alpha
	name = "Alpha Overwatch Console"

/obj/machinery/computer/camera_advanced/overwatch/bravo
	name = "Bravo Overwatch Console"

/obj/machinery/computer/camera_advanced/overwatch/charlie
	name = "Charlie Overwatch Console"

/obj/machinery/computer/camera_advanced/overwatch/delta
	name = "Delta Overwatch Console"

/obj/machinery/computer/camera_advanced/overwatch/req
	icon_state = "overwatch_req"
	screen_overlay = "overwatch_req_screen"
	name = "Requisition Overwatch Console"
	desc = "Big Brother Requisition demands to see money flowing into the void that is greed."
	circuit = /obj/item/circuitboard/computer/supplyoverwatch

/obj/machinery/computer/camera_advanced/overwatch/som
	faction = FACTION_SOM
	icon_state = "som_console"
	screen_overlay = "som_overwatch_emissive"
	light_color = LIGHT_COLOR_FLARE
	networks = list(SOM_CAMERA_NETWORK)
	req_access = list(ACCESS_MARINE_BRIDGE)
	map_flags = MINIMAP_FLAG_MARINE_SOM

/obj/machinery/computer/camera_advanced/overwatch/main/som
	faction = FACTION_SOM
	icon_state = "som_console"
	screen_overlay = "som_main_overwatch_emissive"
	light_color = LIGHT_COLOR_FLARE
	networks = list(SOM_CAMERA_NETWORK)
	req_access = list(ACCESS_MARINE_BRIDGE)
	map_flags = MINIMAP_FLAG_MARINE_SOM

/obj/machinery/computer/camera_advanced/overwatch/som/zulu
	name = "\improper Zulu Overwatch Console"

/obj/machinery/computer/camera_advanced/overwatch/som/yankee
	name = "\improper Yankee Overwatch Console"

/obj/machinery/computer/camera_advanced/overwatch/som/xray
	name = "\improper X-ray Overwatch Console"

/obj/machinery/computer/camera_advanced/overwatch/som/whiskey
	name = "\improper Whiskey Overwatch Console"

/obj/machinery/computer/camera_advanced/overwatch/CreateEye()
	eyeobj = new(null, parent_cameranet, faction)
	eyeobj.origin = src
	RegisterSignal(eyeobj, COMSIG_QDELETING, PROC_REF(clear_eye_ref))
	eyeobj.visible_icon = TRUE
	eyeobj.icon = 'icons/mob/cameramob.dmi'
	eyeobj.icon_state = "generic_camera"
	cic_mini.override_locator(eyeobj)

/obj/machinery/computer/camera_advanced/overwatch/give_eye_control(mob/user)
	. = ..()
	RegisterSignal(user, COMSIG_MOB_CLICK_SHIFT, PROC_REF(send_order))
	RegisterSignal(user, COMSIG_ORDER_SELECTED, PROC_REF(set_order))
	RegisterSignal(user, COMSIG_MOB_MIDDLE_CLICK, PROC_REF(attempt_radial))
	RegisterSignal(SSdcs, COMSIG_GLOB_OB_LASER_CREATED, PROC_REF(alert_lase))

/obj/machinery/computer/camera_advanced/overwatch/remove_eye_control(mob/living/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_CLICK_SHIFT)
	UnregisterSignal(user, COMSIG_ORDER_SELECTED)
	UnregisterSignal(user, COMSIG_MOB_MIDDLE_CLICK)
	UnregisterSignal(SSdcs, COMSIG_GLOB_OB_LASER_CREATED)

/obj/machinery/computer/camera_advanced/overwatch/can_interact(mob/user)
	. = ..()
	if(!.)
		return FALSE

	if(!allowed(user))
		return FALSE

	return TRUE

/obj/machinery/computer/camera_advanced/overwatch/interact(mob/user)
	. = ..()
	if(.)
		return

	ui_interact(user)

/obj/machinery/computer/camera_advanced/overwatch/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		ui = new(user, src, "OverwatchConsole", name)
		ui.open()

/obj/machinery/computer/camera_advanced/overwatch/ui_data(mob/user)
	var/list/data = list()

	if(!current_squad)
		data["watchable_squads"] = list()
		for(var/datum/squad/possible_squad AS in SSjob.active_squads[faction])
			if(!possible_squad.overwatch_officer)
				data["watchable_squads"] += possible_squad.name
		return data // Squad information first, otherwise you will FUCK SHIT UP

	// While in squad select, the default theme will be used as only squad data is sent in that state
	if(faction == FACTION_SOM)
		data["theme"] = "som"
	else if(faction == FACTION_TERRAGOV)
		switch(current_squad.id)
			if(ALPHA_SQUAD)
				data["theme"] = "overwatch-alpha"
			if(BRAVO_SQUAD)
				data["theme"] = "overwatch-bravo"
			if(CHARLIE_SQUAD)
				data["theme"] = "overwatch-charlie"
			if(DELTA_SQUAD)
				data["theme"] = "overwatch-delta"

	data["operator"] = operator.name

	data["current_squad"] = current_squad.name
	data["active_primary_objective"] = current_squad.primary_objective
	data["active_secondary_objective"] = current_squad.secondary_objective

	data["orbital_cannon"] = GLOB.marine_main_ship.orbital_cannon

	data["orbital_targets"] = list()
	for(var/obj/effect/overlay/temp/laser_target/orbital_laser in GLOB.active_laser_targets)
		if(!istype(orbital_laser))
			data["active_orbital_target"] = null
			continue
		var/targets_data = list(list("name" = orbital_laser.name, "ref" = REF(orbital_laser)))
		data["orbital_targets"] += targets_data
	if(selected_target)
		data["active_orbital_target"] = selected_target
	if(GLOB.marine_main_ship.orbital_cannon)
		data["orbital_ammunition"] = GLOB.marine_main_ship.orbital_cannon.chambered_tray

	data["marines"] = list()

	var/leader_count = 0
	var/medic_count = 0
	var/engi_count = 0
	var/smart_count = 0
	var/marine_count = 0

	var/leaders_alive = 0
	var/medic_alive= 0
	var/engi_alive = 0
	var/smart_alive = 0
	var/marines_alive = 0

	var/SL_z //z level of the Squad Leader
	if(current_squad.squad_leader)
		var/turf/SL_turf = get_turf(current_squad.squad_leader)
		SL_z = SL_turf.z

	for(var/marine in current_squad.marines_list)
		if(!marine)
			continue //just to be safe
		var/mob_name = "unknown"
		var/mob_state = ""
		var/role = "unknown"
		var/acting_sl = ""
		var/fteam = "" // fireteams aren't really used here but we keep this anyway :)
		var/distance = "???"
		var/area_name = "???"
		var/is_squad_leader = FALSE
		var/mob/living/carbon/human/marine_human


		if(ishuman(marine))
			marine_human = marine
			if(istype(marine_human.loc, /obj/machinery/cryopod)) //We don't care much for these
				continue
			mob_name = marine_human.real_name
			var/area/current_area = get_area(marine_human)
			var/turf/current_turf = get_turf(marine_human)
			if(!current_turf)
				continue
			if(current_area)
				area_name = sanitize(current_area.name)

			switch(z_hidden)
				if(HIDE_ON_SHIP)
					if(is_mainship_level(current_turf.z))
						continue
				if(HIDE_ON_GROUND)
					if(is_ground_level(current_turf.z))
						continue

			if(marine_human.job)
				role = marine_human.job.title
			else if(istype(marine_human.wear_id, /obj/item/card/id)) //decapitated marine is mindless
				var/obj/item/card/id/ID = marine_human.wear_id //we use their ID to get their role, hopefully they have one!!!!
				if(ID.rank)
					role = ID.rank


			if(current_squad.squad_leader)
				if(marine_human == current_squad.squad_leader)
					distance = "N/A"
					if(marine_human.job != SQUAD_LEADER)
						acting_sl = " (acting SL)"
					is_squad_leader = TRUE
				else if(current_turf && (current_turf.z == SL_z))
					distance = "[get_dist(marine_human, current_squad.squad_leader)]"


			switch(marine_human.stat)
				if(CONSCIOUS)
					mob_state = "Conscious"

				if(UNCONSCIOUS)
					mob_state = "Unconscious"

				if(DEAD)
					mob_state = "Dead"

			if(!marine_human.key || !marine_human.client)
				if(marine_human.stat != DEAD)
					mob_state += " (SSD)"


			if(marine_human.wear_id?.assigned_fireteam)
				fteam = " [marine_human.wear_id?.assigned_fireteam]"

		else //listed marine was deleted or gibbed, all we have is their name
			mob_state = "Dead"
			mob_name = marine


		switch(marine_human.job.title)
			if(SQUAD_LEADER)
				leader_count++
				if(mob_state != "Dead")
					leaders_alive++
			if(SQUAD_CORPSMAN)
				medic_count++
				if(mob_state != "Dead")
					medic_alive++
			if(SQUAD_ENGINEER)
				engi_count++
				if(mob_state != "Dead")
					engi_alive++
			if(SQUAD_SMARTGUNNER)
				smart_count++
				if(mob_state != "Dead")
					smart_alive++
			if(SQUAD_MARINE)
				marine_count++
				if(mob_state != "Dead")
					marines_alive++

		var/marine_data = list(list("name" = mob_name, "state" = mob_state, "role" = role, "acting_sl" = acting_sl, "fteam" = fteam, "distance" = distance, "area_name" = area_name,"ref" = REF(marine)))
		data["marines"] += marine_data
		if(is_squad_leader)
			if(!data["squad_leader"])
				data["squad_leader"] = marine_data[1]

	data["total_deployed"] = leader_count + medic_count + engi_count + smart_count + marine_count
	data["living_count"] = leaders_alive + medic_alive + engi_alive + smart_alive + marines_alive

	data["leader_count"] = leader_count
	data["medic_count"] = medic_count
	data["engi_count"] = engi_count
	data["smart_count"] = smart_count

	data["leaders_alive"] = leaders_alive
	data["medic_alive"] = medic_alive
	data["engi_alive"] = engi_alive
	data["smart_alive"] = smart_alive

	data["z_hidden"] = z_hidden

	return data

/obj/machinery/computer/camera_advanced/overwatch/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("pick_squad")
			if(current_squad)
				return
			var/datum/squad/selected_squad
			for(var/datum/squad/searching_squad in SSjob.active_squads[faction])
				if(searching_squad.name == params["picked"])
					selected_squad = searching_squad
					break
			if(!selected_squad)
				return
			current_squad = selected_squad
			operator = usr
			if(issilicon(operator))
				to_chat(operator, span_boldnotice("Tactical data for squad '[current_squad]' loaded. All tactical functions initialized."))
			visible_message(span_boldnotice("Tactical data for squad '[current_squad]' loaded. All tactical functions initialized."))
			for(var/mob/living/squad_receivers AS in current_squad.marines_list)
				to_chat(squad_receivers, assemble_alert(
					title = "Overwatch",
					message = "Your squad has been selected for Overwatch. Your current Overwatch Officer is [operator ? operator.name : "system admin"].",
					minor = TRUE,
					color_override = "grey"
					))
			attack_hand(operator)
		if("change_operator")
			if(operator != usr)
				if(current_squad)
					current_squad.overwatch_officer = usr
				operator = usr
				var/mob/living/carbon/human/H = operator
				var/obj/item/card/id/ID = H.get_idcard()
				if(issilicon(operator))
					to_chat(operator, span_boldnotice("Basic overwatch systems initialized. Welcome, [ID ? "[ID.rank] ":""][operator.name]. Please select a squad."))
				visible_message(span_boldnotice("Basic overwatch systems initialized. Welcome, [ID ? "[ID.rank] ":""][operator.name]. Please select a squad."))
		if("logout")
			if(!current_squad)
				return
			var/obj/item/card/id/ID = operator.get_idcard()
			current_squad.overwatch_officer = null //Reset the squad's officer.
			if(issilicon(operator))
				to_chat(operator, span_boldnotice("Overwatch systems deactivated. Goodbye, [ID ? "[ID.rank] ":""][operator ? "[operator.name]":"sysadmin"]."))
			visible_message(span_boldnotice("Overwatch systems deactivated. Goodbye, [ID ? "[ID.rank] ":""][operator ? "[operator.name]":"sysadmin"]."))
			operator = null
			current_squad = null
			ui.close()
		if("message")
			if(current_squad && operator == usr)
				var/input = tgui_input_text(operator, "Please write a message to announce to the squad:", "Squad Message")
				if(input)
					current_squad.message_squad(input, operator) //message, adds username
					if(issilicon(operator))
						to_chat(operator, span_boldnotice("Message sent to all Marines of squad '[current_squad]'."))
					visible_message(span_boldnotice("Message sent to all Marines of squad '[current_squad]'."))
		if("sl_message")
			if(current_squad && operator == usr)
				var/input = tgui_input_text(operator, "Please write a message to announce to the squad leader:", "SL Message")
				if(input)
					message_member(current_squad.squad_leader, input, operator)
					if(issilicon(operator))
						to_chat(operator, span_boldnotice("Message sent to Squad Leader [current_squad.squad_leader] of squad '[current_squad]'."))
					visible_message(span_boldnotice("Message sent to Squad Leader [current_squad.squad_leader] of squad '[current_squad]'."))
		if("set_primary")
			var/input = tgui_input_text(operator, "What will be the squad's primary objective?", "Primary Objective")
			if(is_ic_filtered(input) || NON_ASCII_CHECK(input))
				to_chat(operator, span_warning("That message contained a word prohibited in IC chat! Consider reviewing the server rules.\n<span replaceRegex='show_filtered_ic_chat'>\"[input]\"</span>"))
				SSblackbox.record_feedback(FEEDBACK_TALLY, "ic_blocked_words", 1, lowertext(config.ic_filter_regex.match))
				REPORT_CHAT_FILTER_TO_USER(src, input)
				log_filter("IC", text, input)
				return
			current_squad.primary_objective = input + " ([worldtime2text()])"
			current_squad.message_squad("Primary objective updated; see game panel for details.")
			if(issilicon(operator))
				to_chat(operator, span_boldnotice("Primary objective of squad '[current_squad]' set."))
			visible_message(span_boldnotice("Primary objective of squad '[current_squad]' set."))
		if("set_secondary")
			var/input = tgui_input_text(operator, "What will be the squad's secondary objective?", "Secondary Objective")
			if(is_ic_filtered(input) || NON_ASCII_CHECK(input))
				to_chat(operator, span_warning("That message contained a word prohibited in IC chat! Consider reviewing the server rules.\n<span replaceRegex='show_filtered_ic_chat'>\"[input]\"</span>"))
				SSblackbox.record_feedback(FEEDBACK_TALLY, "ic_blocked_words", 1, lowertext(config.ic_filter_regex.match))
				REPORT_CHAT_FILTER_TO_USER(src, input)
				log_filter("IC", text, input)
				return
			current_squad.secondary_objective = input + " ([worldtime2text()])"
			current_squad.message_squad("Secondary objective updated; see game panel for details.")
			if(issilicon(operator))
				to_chat(operator, span_boldnotice("Secondary objective of squad '[current_squad]' set."))
			visible_message(span_boldnotice("Secondary objective of squad '[current_squad]' set."))
		if("change_sort")
			living_marines_sorting = !living_marines_sorting
			if(living_marines_sorting)
				to_chat(operator, "[icon2html(src, operator)] [span_notice("Marines are now sorted by health status.")]")
			else
				to_chat(operator, "[icon2html(src, operator)] [span_notice("Marines are now sorted by rank.")]")
		if("hide_dead")
			dead_hidden = !dead_hidden
			if(dead_hidden)
				to_chat(operator, "[icon2html(src, operator)] [span_notice("Dead marines are now not shown.")]")
			else
				to_chat(operator, "[icon2html(src, operator)] [span_notice("Dead marines are now shown again.")]")
		if("choose_z")
			switch(z_hidden)
				if(HIDE_NONE)
					z_hidden = HIDE_ON_SHIP
					to_chat(operator, "[icon2html(src, operator)] [span_notice("Marines on the [SSmapping.configs[SHIP_MAP].map_name] are now hidden.")]")
				if(HIDE_ON_SHIP)
					z_hidden = HIDE_ON_GROUND
					to_chat(operator, "[icon2html(src, operator)] [span_notice("Marines on the ground are now hidden.")]")
				if(HIDE_ON_GROUND)
					z_hidden = HIDE_NONE
					to_chat(operator, "[icon2html(src, operator)] [span_notice("No location is ignored anymore.")]")
		if("replace_lead")
			if(!params["target"])
				return
			var/mob/living/carbon/human/leader_target = params["target"]
			change_lead(operator, leader_target)
		if("insubordination")
			mark_insubordination()
		if("squad_transfer")
			if(!current_squad)
				to_chat(operator, "[icon2html(src, operator)] [span_warning("No squad selected!")]")
				return
			var/datum/squad/S = current_squad
			var/mob/living/carbon/human/transfer_marine = tgui_input_list(operator, "Choose marine to transfer", "Marine", current_squad.get_all_members())
			var/datum/squad/target_squad = tgui_input_list(operator, "Choose the marine's new squad", "New Squad",  watchable_squads)

			if(!transfer_marine)
				return
			if(S != current_squad)
				return //don't change overwatched squad, idiot.

			transfer_squad(operator, transfer_marine, target_squad)
		if("change_orbital_target")
			if(!params["target"])
				return
			selected_target = REF(params["target"])
		if("dropbomb")
			handle_bombard()
		if("shootrailgun")
			if(operator.interactee != src)
				to_chat(operator, "[icon2html(src, operator)] [span_warning("You're busy doing something else, and press the wrong button!")]")
				return
			if((GLOB.marine_main_ship?.rail_gun?.last_firing + 600) > world.time)
				to_chat(operator, "[icon2html(src, operator)] [span_warning("The Rail Gun hasn't cooled down yet!")]")
			else if(!selected_target)
				to_chat(operator, "[icon2html(src, operator)] [span_warning("No target detected!")]")
			else
				GLOB.marine_main_ship?.rail_gun?.fire_rail_gun(get_turf(selected_target),operator)
		if("back")
			state = OW_MAIN
		if("use_cam")
			var/atom/cam_target = locate(params["cam_target"])
			if(!cam_target)
				return
			var/turf/cam_target_turf = get_turf(cam_target)
			if(!cam_target_turf)
				return
			if(!isAI(operator))
				open_prompt(operator)
				eyeobj.setLoc(cam_target_turf)
				if(isliving(cam_target))
					var/mob/living/L = cam_target
					track(L)
				else
					to_chat(operator, "[icon2html(src, operator)] [span_notice("Jumping to the latest available location of [cam_target].")]")
			else
				// If we are an AI
				to_chat(operator, "[icon2html(src, operator)] [span_notice("Jumping to the latest available location of [cam_target].")]")
				var/turf/T = get_turf(cam_target)
				if(T)
					var/mob/living/silicon/ai/recipientai = operator
					recipientai.eyeobj.setLoc(T)
					// operator.eyeobj.setLoc(get_turf(src))

/obj/machinery/computer/camera_advanced/overwatch/proc/send_to_squads(txt)
	for(var/datum/squad/squad AS in watchable_squads)
		squad.message_squad(txt)

///Checks and warnings before OB starts to fire
/obj/machinery/computer/camera_advanced/overwatch/proc/handle_bombard()
	if(!operator)
		return
	if(busy)
		to_chat(operator, "[icon2html(src, operator)] [span_warning("The [name] is busy processing another action!")]")
		return
	if(!GLOB.marine_main_ship?.orbital_cannon?.chambered_tray)
		to_chat(operator, "[icon2html(src, operator)] [span_warning("The orbital cannon has no ammo chambered.")]")
		return
	if(!selected_target)
		to_chat(operator, "[icon2html(src, operator)] [span_warning("No target detected!")]")
		return
	var/area/A = get_area(selected_target)
	if(istype(A) && A.ceiling >= CEILING_UNDERGROUND)
		to_chat(operator, "[icon2html(src, operator)] [span_warning("The target's signal is too weak.")]")
		return
	var/turf/T = get_turf(selected_target)
	if(!isturf(T)) //Huh?
		to_chat(operator, "[icon2html(src, operator)] [span_warning("Invalid target.")]")
		return
	if(isspaceturf(T))
		to_chat(operator, "[icon2html(src, operator)] [span_warning("The target's landing zone appears to be out of bounds.")]")
		return
	busy = TRUE //All set, let's do this.
	var/warhead_type = GLOB.marine_main_ship.orbital_cannon.tray.warhead.name	//For the AI and Admin logs.

	for(var/mob/living/silicon/ai/AI AS in GLOB.ai_list)
		to_chat(AI, span_warning("NOTICE - Orbital bombardment triggered from overwatch consoles. Warhead type: [warhead_type]. Target: [AREACOORD_NO_Z(T)]"))
		playsound(AI,'sound/machines/triple_beep.ogg', 25, 1, 20)

	if(A)
		log_attack("[key_name(operator)] fired a [warhead_type]in for squad [current_squad] in [AREACOORD(T)].")
		message_admins("[ADMIN_TPMONTY(operator)] fired a [warhead_type]for squad [current_squad] in [ADMIN_VERBOSEJMP(T)].")
	visible_message(span_boldnotice("Orbital bombardment request accepted. Orbital cannons are now calibrating."))
	send_to_squads("ORBITAL BOMBARDMENT INBOUND AT [get_area(selected_target)]! Type: [warhead_type]!")
	if(selected_target)
		playsound(selected_target.loc,'sound/effects/alert.ogg', 50, 1, 20)  //mostly used to warn xenos as the new ob sounds have a quiet beginning

	addtimer(CALLBACK(src, PROC_REF(do_fire_bombard), T, operator), 3.1 SECONDS)

///Lets anyone using an overwatch console know that an OB has just been lased
/obj/machinery/computer/camera_advanced/overwatch/proc/alert_lase(datum/source, obj/effect/overlay/temp/laser_target/ob/incoming_laser)
	SIGNAL_HANDLER
	if(!operator)
		return
	to_chat(operator, span_notice("Orbital Bombardment laser detected. Target: [AREACOORD_NO_Z(incoming_laser)]"))
	operator.playsound_local(source, 'sound/effects/binoctarget.ogg', 15)

///About to fire
/obj/machinery/computer/camera_advanced/overwatch/proc/do_fire_bombard(turf/T, user)
	visible_message(span_boldnotice("Orbital bombardment has fired! Impact imminent!"))
	addtimer(CALLBACK(src, PROC_REF(do_land_bombard), T, user), 2.5 SECONDS)

///Randomises OB impact location a little and tells the OB cannon to fire
/obj/machinery/computer/camera_advanced/overwatch/proc/do_land_bombard(turf/T, user)
	busy = FALSE
	var/x_offset = rand(-2,2) //Little bit of randomness.
	var/y_offset = rand(-2,2)
	var/turf/target = locate(T.x + x_offset,T.y + y_offset,T.z)
	if(target && istype(target))
		target.ceiling_debris_check(5)
		GLOB.marine_main_ship?.orbital_cannon?.fire_ob_cannon(target,user)

/obj/machinery/computer/camera_advanced/overwatch/proc/change_lead(datum/source, mob/living/carbon/human/target)
	if(!operator)
		return

	if(!current_squad)
		return

	var/mob/living/carbon/human/selected_sl = locate(target) in current_squad.get_all_members()
	var/datum/squad/target_squad = selected_sl.assigned_squad
	if(!selected_sl)
		return
	if(!istype(selected_sl))
		return

	if(!istype(selected_sl) || !selected_sl.mind || selected_sl.stat == DEAD) //marines_list replaces mob refs of marines with just a name string
		to_chat(source, "[icon2html(src, usr)] [span_warning("[selected_sl] can't be promoted right now!")]")
		return
	if(selected_sl == target_squad.squad_leader)
		to_chat(source, "[icon2html(src, source)] [span_warning("[selected_sl] is already the Squad Leader!")]")
		return
	if(is_banned_from(selected_sl.ckey, SQUAD_LEADER))
		to_chat(source, "[icon2html(src, source)] [span_warning("[selected_sl] is unfit to lead!")]")
		return
	if(target_squad.squad_leader)
		target_squad.message_squad("Acting Squad Leader updated to [selected_sl.real_name].")
		if(issilicon(source))
			to_chat(source, span_boldnotice("Squad Leader [target_squad.squad_leader] of squad '[target_squad]' has been [target_squad.squad_leader.stat == DEAD ? "replaced" : "demoted and replaced"] by [selected_sl.real_name]! Logging to enlistment files."))
		visible_message(span_boldnotice("Squad Leader [target_squad.squad_leader] of squad '[target_squad]' has been [target_squad.squad_leader.stat == DEAD ? "replaced" : "demoted and replaced"] by [selected_sl.real_name]! Logging to enlistment files."))
		target_squad.demote_leader()
	else
		target_squad.message_squad("Acting Squad Leader updated to [selected_sl.real_name].")
		if(issilicon(source))
			to_chat(source, span_boldnotice("[selected_sl.real_name] is the new Squad Leader of squad '[target_squad]'! Logging to enlistment file."))
		visible_message(span_boldnotice("[selected_sl.real_name] is the new Squad Leader of squad '[target_squad]'! Logging to enlistment file."))

	to_chat(target, "[icon2html(src, selected_sl)] <font size='3' color='blue'><B>\[Overwatch\]: You've been promoted to \'[(ismarineleaderjob(selected_sl.job) || issommarineleaderjob(selected_sl.job)) ? "SQUAD LEADER" : "ACTING SQUAD LEADER"]\' for [target_squad.name]. Your headset has access to the command channel (:v).</B></font>")
	to_chat(source, "[icon2html(src, source)] [selected_sl.real_name] is [target_squad]'s new leader!")
	target_squad.promote_leader(selected_sl)

///Mark a marine for insubordination. This would be a really good candidate for removal, we don't have MPs anymore
/obj/machinery/computer/camera_advanced/overwatch/proc/mark_insubordination()
	if(!usr || usr != operator)
		return
	if(!current_squad)
		to_chat(operator, "[icon2html(src, operator)] [span_warning("No squad selected!")]")
		return
	var/mob/living/carbon/human/wanted_marine = tgui_input_list(operator, "Report a marine for insubordination", null, current_squad.get_all_members())
	if(!wanted_marine) return
	if(!istype(wanted_marine))//gibbed/deleted, all we have is a name.
		to_chat(operator, "[icon2html(src, operator)] [span_warning("[wanted_marine] is missing in action.")]")
		return

	for (var/datum/data/record/E in GLOB.datacore.general)
		if(E.fields["name"] == wanted_marine.real_name)
			for (var/datum/data/record/R in GLOB.datacore.security)
				if (R.fields["id"] == E.fields["id"])
					if(!findtext(R.fields["ma_crim"],"Insubordination."))
						R.fields["criminal"] = "*Arrest*"
						if(R.fields["ma_crim"] == "None")
							R.fields["ma_crim"] = "Insubordination."
						else
							R.fields["ma_crim"] += "Insubordination."
						if(issilicon(operator))
							to_chat(operator, span_boldnotice("[wanted_marine] has been reported for insubordination. Logging to enlistment file."))
						visible_message(span_boldnotice("[wanted_marine] has been reported for insubordination. Logging to enlistment file."))
						to_chat(wanted_marine, "[icon2html(src, wanted_marine)] <font size='3' color='blue'><B>\[Overwatch\]:</b> You've been reported for insubordination by your overwatch officer.</font>")
						wanted_marine.sec_hud_set_security_status()
					return

/**
 * Transfer someone to another squad
 *
 * Arguments
 * * source: Who called this? Should be the `operator` of the computer.
 * * transfer_marine: The marine to transfer
 * * new_squad: The squad to send them to
 */
/obj/machinery/computer/camera_advanced/overwatch/proc/transfer_squad(datum/source, mob/living/carbon/human/transfer_marine, datum/squad/new_squad)
	if(!source || source != operator)
		return

	var/mob/living/carbon/human/selected_marine = transfer_marine

	if(!istype(selected_marine)) //gibbed
		to_chat(source, "[icon2html(src, source)] [span_warning("[selected_marine] is KIA.")]")
		return

	if(!istype(selected_marine.wear_id, /obj/item/card/id))
		to_chat(source, "[icon2html(src, source)] [span_warning("Transfer aborted. [selected_marine] isn't wearing an ID.")]")
		return

	if(!new_squad)
		return

	if((ismarineleaderjob(selected_marine.job) || issommarineleaderjob(selected_marine.job)) && new_squad.current_positions[selected_marine.job.type] >= SQUAD_MAX_POSITIONS(selected_marine.job.total_positions))
		to_chat(source, "[icon2html(src, source)] [span_warning("Transfer aborted. [new_squad] can't have another [selected_marine.job.title].")]")
		return

	var/datum/squad/old_squad = selected_marine.assigned_squad
	if(new_squad == old_squad)
		to_chat(source, "[icon2html(src, source)] [span_warning("[selected_marine] is already in [new_squad]!")]")
		return

	if(old_squad)
		if(old_squad.squad_leader == selected_marine)
			old_squad.demote_leader()
		old_squad.remove_from_squad(selected_marine)
	new_squad.insert_into_squad(selected_marine)

	for(var/datum/data/record/t in GLOB.datacore.general) //we update the crew manifest
		if(t.fields["name"] == selected_marine.real_name)
			t.fields["squad"] = new_squad.name
			break

	var/obj/item/card/id/ID = selected_marine.wear_id
	ID.assigned_fireteam = 0 //reset fireteam assignment

	//Changes headset frequency to match new squad
	var/obj/item/radio/headset/mainship/marine/headset = selected_marine.wear_ear
	if(istype(headset, /obj/item/radio/headset/mainship/marine))
		headset.set_frequency(new_squad.radio_freq)

	selected_marine.hud_set_job()
	if(issilicon(source))
		to_chat(source, span_boldnotice("[selected_marine] has been transfered from squad '[old_squad]' to squad '[new_squad]'. Logging to enlistment file."))
	visible_message(span_boldnotice("[selected_marine] has been transfered from squad '[old_squad]' to squad '[new_squad]'. Logging to enlistment file."))
	to_chat(selected_marine, "[icon2html(src, selected_marine)] <font size='3' color='blue'><B>\[Overwatch\]:</b> You've been transfered to [new_squad]!</font>")

/**
 * Message a squad member
 *
 * Arguments
 * * target: The target of this message
 * * message: The content of the message
 * * sender: The sender of this message
 */
/obj/machinery/computer/camera_advanced/overwatch/proc/message_member(mob/living/target, message, mob/living/carbon/human/sender)
	if(!target.client)
		return
	target.play_screen_text("<span class='maptext' style=font-size:24pt;text-align:center valign='top'><u>CIC MESSAGE FROM [sender.real_name]:</u></span><br>" + message, /atom/movable/screen/text/screen_text/command_order)
	return TRUE

///Signal handler for radial menu
/obj/machinery/computer/camera_advanced/overwatch/proc/attempt_radial(datum/source, atom/A, params)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(do_radial), source, A, params)

///Quick-select radial menu for Overwatch
/obj/machinery/computer/camera_advanced/overwatch/proc/do_radial(datum/source, atom/A, params)
	var/mob/living/carbon/human/human_target
	var/obj/effect/overlay/temp/laser_target/ob/laser_target
	var/turf/turf_target
	var/choice
	if(ishuman(A))
		human_target = A
		choice = show_radial_menu(source, human_target, human_radial_options, null, 48, null, FALSE, TRUE)

	else if(istype(A, /obj/effect/overlay/temp/laser_target/ob))
		laser_target = A
		choice = show_radial_menu(source, laser_target, bombardment_radial_options, null, 48, null, FALSE, TRUE)
	else
		turf_target = get_turf(A)
		choice = show_radial_menu(source, turf_target, turf_radial_options, null, 48, null, FALSE, TRUE)

	switch(choice)
		if(MESSAGE_SINGLE)
			var/input = tgui_input_text(source, "Please write a message to announce to this marine:", "CIC Message")
			message_member(human_target, input, source)
		if(ASL)
			if(human_target == human_target.assigned_squad.squad_leader)
				human_target.assigned_squad.demote_leader()
				return
			change_lead(source, human_target)
		if(SWITCH_SQUAD)
			var/datum/squad/desired_squad = squad_select(source, human_target)
			transfer_squad(source, human_target, desired_squad)
		if(MARK_LASE)
			if(marked_lase)
				remove_mark_from_lase() //There can only be one
				marked_lase = laser_target
			SSminimaps.add_marker(laser_target, MINIMAP_FLAG_ALL, image('icons/UI_icons/map_blips.dmi', null, "ob_warning", VERY_HIGH_FLOAT_LAYER))
			addtimer(CALLBACK(src, PROC_REF(remove_mark_from_lase)), 30 SECONDS)
		if(FIRE_LASE)
			selected_target = laser_target
			handle_bombard()
		if(ORBITAL_SPOTLIGHT)
			attempt_spotlight(source, turf_target, params)
		if(MESSAGE_NEAR)
			var/input = tgui_input_text(source, "Please write a message to announce to all marines nearby:", "CIC Proximity Message")
			for(var/mob/living/carbon/human/target in GLOB.alive_human_list_faction[faction])
				if(!target)
					return
				if(get_dist(target, turf_target) > WORLD_VIEW_NUM*2)
					continue
				message_member(target, input, source)
			message_member(source, input, source)
		if(SQUAD_ACTIONS)
			choice = show_radial_menu(source, turf_target, squad_radial_options, null, 48, null, FALSE, TRUE)
			var/datum/squad/chosen_squad = squad_select(source, turf_target)
			switch(choice)
				if(MESSAGE_SQUAD)
					var/input = tgui_input_text(source, "Please write a message to announce to the squad:", "Squad Message")
					if(input)
						chosen_squad.message_squad(input, source)
				if(SWITCH_SQUAD_NEAR)
					for(var/mob/living/carbon/human/target in GLOB.human_mob_list)
						if(!target.faction == faction || get_dist(target, turf_target) > 9)
							continue
						transfer_squad(source, target, chosen_squad)

///Radial squad select menu.
/obj/machinery/computer/camera_advanced/overwatch/proc/squad_select(datum/source, atom/A)
	var/list/squad_options = list()

	for(var/datum/squad/squad AS in watchable_squads)
		var/image/squad_icon = image(icon = 'icons/mob/radial.dmi', icon_state = "cic_squad_box")
		squad_icon.color = squad.color
		squad_options += list(squad.name = squad_icon)

	return SSjob.squads_by_name[faction][show_radial_menu(source, A, squad_options, null, 48, null, FALSE, TRUE)]

///Removes any active marks on OB lases, if any
/obj/machinery/computer/camera_advanced/overwatch/proc/remove_mark_from_lase()
	if(marked_lase)
		SSminimaps.remove_marker(marked_lase)
		marked_lase = null

///This is an orbital light. Basically, huge thing which the CIC can use to light up areas for a bit of time.
/obj/machinery/computer/camera_advanced/overwatch/proc/attempt_spotlight(datum/source, atom/A, params)
	if(!powered())
		return 0

	var/area/here_we_are = get_area(src)
	var/obj/machinery/power/apc/myAPC = here_we_are.get_apc()

	var/power_amount = myAPC?.terminal?.powernet?.avail

	if(power_amount <= 10000)
		return

	if(TIMER_COOLDOWN_CHECK(src, COOLDOWN_ORBITAL_SPOTLIGHT))
		to_chat(source, span_notice("The Orbital spotlight is still recharging."))
		return
	var/area/place = get_area(A)
	if(istype(place) && place.ceiling >= CEILING_UNDERGROUND)
		to_chat(source, span_warning("You cannot illuminate this place. It is probably underground."))
		return
	var/turf/target = get_turf(A)
	if(!target)
		return
	new /obj/effect/overwatch_light(target)
	use_power(10000)	//Huge light needs big power. Still less than autodocs.
	TIMER_COOLDOWN_START(src, COOLDOWN_ORBITAL_SPOTLIGHT, SPOTLIGHT_COOLDOWN_DURATION)
	to_chat(source, span_notice("Orbital spotlight activated. Duration : [SPOTLIGHT_DURATION]"))

//This is an effect to be sure it is properly deleted and it does not interfer with existing lights too much.
/obj/effect/overwatch_light
	name = "overwatch beam of light"
	desc = "You are not supposed to see this. Please report it."
	icon_state = "" //No sprite
	invisibility = INVISIBILITY_MAXIMUM
	resistance_flags = RESIST_ALL
	light_system = STATIC_LIGHT
	light_color = COLOR_TESLA_BLUE
	light_range = 15	//This is a HUGE light.
	light_power = SQRTWO

/obj/effect/overwatch_light/Initialize(mapload)
	. = ..()
	set_light(light_range, light_power)
	playsound(src,'sound/mecha/heavylightswitch.ogg', 25, 1, 20)
	visible_message(span_warning("You see a twinkle in the sky before your surroundings are hit with a beam of light!"))
	QDEL_IN(src, SPOTLIGHT_DURATION)

//This is perhaps one of the weirdest places imaginable to put it, but it's a leadership skill, so

/mob/living/carbon/human/verb/issue_order(command_aura as null|text)
	set hidden = TRUE

	if(skills.getRating(SKILL_LEADERSHIP) < SKILL_LEAD_TRAINED)
		to_chat(src, span_warning("You are not competent enough in leadership to issue an order."))
		return

	if(stat)
		to_chat(src, span_warning("You cannot give an order in your current state."))
		return

	if(IsMute())
		to_chat(src, span_warning("You cannot give an order while muted."))
		return

	if(command_aura_cooldown)
		to_chat(src, span_warning("You have recently given an order. Calm down."))
		return

	if(!command_aura)
		command_aura = tgui_input_list(src, "Choose an order", items = command_aura_allowed + "help")
		if(command_aura == "help")
			to_chat(src, span_notice("<br>Orders give a buff to nearby marines for a short period of time, followed by a cooldown, as follows:<br><B>Move</B> - Increased mobility and chance to dodge projectiles.<br><B>Hold</B> - Increased resistance to pain and combat wounds.<br><B>Focus</B> - Increased gun accuracy and effective range.<br>"))
			return
		if(!command_aura)
			return

	if(command_aura_cooldown)
		to_chat(src, span_warning("You have recently given an order. Calm down."))
		return

	if(!(command_aura in command_aura_allowed))
		return
	var/aura_strength = skills.getRating(SKILL_LEADERSHIP) - 1
	var/aura_target = pick_order_target()
	SSaura.add_emitter(aura_target, command_aura, aura_strength + 4, aura_strength, 30 SECONDS, faction)

	var/message = ""
	switch(command_aura)
		if("move")
			var/image/move = image('icons/mob/talk.dmi', src, icon_state = "order_move")
			message = pick(";GET MOVING!", ";GO, GO, GO!", ";WE ARE ON THE MOVE!", ";MOVE IT!", ";DOUBLE TIME!", ";ONWARDS!", ";MOVE MOVE MOVE!", ";ON YOUR FEET!", ";GET A MOVE ON!", ";ON THE DOUBLE!", ";ROLL OUT!", ";LET'S GO, LET'S GO!", ";MOVE OUT!", ";LEAD THE WAY!", ";FORWARD!", ";COME ON, MOVE!", ";HURRY, GO!")
			say(message)
			add_emote_overlay(move)
		if("hold")
			var/image/hold = image('icons/mob/talk.dmi', src, icon_state = "order_hold")
			message = pick(";DUCK AND COVER!", ";HOLD THE LINE!", ";HOLD POSITION!", ";STAND YOUR GROUND!", ";STAND AND FIGHT!", ";TAKE COVER!", ";COVER THE AREA!", ";BRACE FOR COVER!", ";BRACE!", ";INCOMING!")
			say(message)
			add_emote_overlay(hold)
		if("focus")
			var/image/focus = image('icons/mob/talk.dmi', src, icon_state = "order_focus")
			message = pick(";FOCUS FIRE!", ";PICK YOUR TARGETS!", ";CENTER MASS!", ";CONTROLLED BURSTS!", ";AIM YOUR SHOTS!", ";READY WEAPONS!", ";TAKE AIM!", ";LINE YOUR SIGHTS!", ";LOCK AND LOAD!", ";GET READY TO FIRE!")
			say(message)
			add_emote_overlay(focus)

	command_aura_cooldown = addtimer(CALLBACK(src, PROC_REF(end_command_aura_cooldown)), 45 SECONDS)

	update_action_buttons()

///Choose what we're sending a buff order through
/mob/living/carbon/human/proc/pick_order_target()
	//If we're in overwatch, use the camera eye
	if(istype(remote_control, /mob/camera/aiEye/remote/hud/overwatch))
		return remote_control
	return src

/mob/living/carbon/human/proc/end_command_aura_cooldown()
	command_aura_cooldown = null
	update_action_buttons()

/datum/action/skill/issue_order
	name = "Issue Order"
	skill_name = SKILL_LEADERSHIP
	action_icon = 'icons/mob/order_icons.dmi'
	skill_min = SKILL_LEAD_TRAINED
	var/order_type = null

/datum/action/skill/issue_order/action_activate()
	var/mob/living/carbon/human/human = owner
	if(istype(human))
		human.issue_order(order_type)

/datum/action/skill/issue_order/update_button_icon()
	var/mob/living/carbon/human/human = owner
	if(!istype(human))
		return
	action_icon_state = "[order_type]"
	return ..()

/datum/action/skill/issue_order/handle_button_status_visuals()
	var/mob/living/carbon/human/human = owner
	if(!istype(human))
		return
	if(human.command_aura_cooldown)
		button.color = rgb(255,0,0,255)
	else
		button.color = rgb(255,255,255,255)

/datum/action/skill/issue_order/move
	name = "Issue Move Order"
	order_type = AURA_HUMAN_MOVE
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_KB_MOVEORDER,
	)

/datum/action/skill/issue_order/hold
	name = "Issue Hold Order"
	order_type = AURA_HUMAN_HOLD
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_KB_HOLDORDER,
	)

/datum/action/skill/issue_order/focus
	name = "Issue Focus Order"
	order_type = AURA_HUMAN_FOCUS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_KB_FOCUSORDER,
	)

/datum/action/skill/toggle_orders
	name = "Show/Hide Order Options"
	skill_name = SKILL_LEADERSHIP
	skill_min = SKILL_LEAD_TRAINED
	var/orders_visible = TRUE
	action_icon_state = "hide_order"

/datum/action/skill/toggle_orders/action_activate()
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return
	if(orders_visible)
		orders_visible = FALSE
		action_icon_state = "show_order"
		for(var/datum/action/skill/path in owner.actions)
			if(istype(path, /datum/action/skill/issue_order))
				path.remove_action(H)
	else
		orders_visible = TRUE
		action_icon_state = "hide_order"
		var/list/subtypeactions = subtypesof(/datum/action/skill/issue_order)
		for(var/path in subtypeactions)
			var/datum/action/skill/issue_order/A = new path()
			A.give_action(H)

///Print order visual to all marines squad hud and give them an arrow to follow the waypoint
/obj/machinery/computer/camera_advanced/overwatch/proc/send_order(datum/source, atom/target)
	SIGNAL_HANDLER
	if(!current_order)
		var/mob/user = source
		to_chat(user, span_warning("You have no order selected."))
		return
	current_order.send_order(target, faction = faction)

///Setter for the current order
/obj/machinery/computer/camera_advanced/overwatch/proc/set_order(datum/source, datum/action/innate/order/order)
	SIGNAL_HANDLER
	current_order = order

#undef OW_MAIN
#undef OW_MONITOR
