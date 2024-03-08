/datum/emote/living/deathgasp
	mob_type_allowed_typecache = /mob/living
	key = "deathgasp"
	key_third_person = "deathgasps"
	message = "seizes up and falls limp, their eyes dead and lifeless..."
	message_AI = "screeches, its screen flickering as its systems slowly halt."
	message_alien = "lets out a waning guttural screech, and collapses onto the floor..."
	message_larva = "lets out a sickly hiss of air and falls limply to the floor..."
	message_monkey = "lets out a faint chimper as it collapses and stops moving..."
	message_simple = "stops moving..."
	cooldown = (15 SECONDS)
	stat_allowed = UNCONSCIOUS

/datum/emote/living/deathgasp/run_emote(mob/living/user, params, type_override, intentional)
	var/species_custom_message = user.death_message
	if(species_custom_message)
		message = species_custom_message
	. = ..()

/datum/emote/living/deathgasp/get_sound(mob/living/user)
	if(user.death_sound)
		return user.death_sound
