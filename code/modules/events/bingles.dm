/datum/event/spawn_bingle
	startWhen = 3

	var/key_of_bingle
	var/mob/living/simple_animal/hostile/bingle/lord/bingle_lord = /mob/living/simple_animal/hostile/bingle/lord


/datum/event/spawn_bingle/proc/get_bingle()
	var/list/candidates = SSghost_spawns.poll_candidates("Вы хотите занять роль [initial(bingle_lord.name)]?", ROLE_BINGLE, TRUE, source = bingle_lord)
	if(!length(candidates))
		kill()
		return

	var/mob/candidate = pick(candidates)
	key_of_bingle = candidate.key

	if(!key_of_bingle)
		kill()
		return

	var/datum/mind/player_mind = new /datum/mind(key_of_bingle)
	player_mind.active = TRUE
	var/turf/spawn_loc = get_spawn_loc(player_mind.current)
	var/mob/living/simple_animal/hostile/bingle/lord/new_bingle_lord = new bingle_lord(spawn_loc)
	player_mind.transfer_to(new_bingle_lord)
	player_mind.assigned_role = ROLE_BINGLE
	player_mind.special_role = SPECIAL_ROLE_BINGLE_LORD
	message_admins("[key_name_admin(new_bingle_lord)] has been made into a [new_bingle_lord.name] by an event.")
	log_game("[key_name_admin(new_bingle_lord)] was spawned as a [new_bingle_lord.name] by an event.")


/datum/event/spawn_bingle/proc/get_spawn_loc(mob/player)
	RETURN_TYPE(/turf)
	var/list/spawn_locs = list()
	for(var/obj/effect/landmark/landmark in GLOB.landmarks_list)
		if(isturf(landmark.loc) && landmark.name == "revenantspawn")
			spawn_locs += landmark.loc
	if(!spawn_locs)	// If we can't find any good spots, try the carp spawns
		spawn_locs += GLOB.carplist
	if(!spawn_locs) //If we can't find a good place, just spawn at the player's location
		spawn_locs += get_turf(player)
	if(!spawn_locs) //If we can't find THAT, then give up
		kill()
		return
	return pick(spawn_locs)


/datum/event/spawn_bingle/start()
	INVOKE_ASYNC(src, PROC_REF(get_bingle))
