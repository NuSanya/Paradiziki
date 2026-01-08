/// Minimum amount of players required to start this event
#define BINGLES_MINPLAYERS_TRIGGER 40

/datum/event/bingles

/datum/event/bingles/start()
	// It is necessary to wrap this to avoid the event triggering repeatedly.
	INVOKE_ASYNC(src, PROC_REF(wrapped_start))

/datum/event/bingles/proc/wrapped_start()
	// Reroll event if not enough players
	var/player_count = num_station_players()
	if(player_count < BINGLES_MINPLAYERS_TRIGGER)
		log_and_message_admins("Random event attempted to spawn bingles, but there were only [player_count]/[BINGLES_MINPLAYERS_TRIGGER] players.")
		var/datum/event_container/EC = SSevents.event_containers[EVENT_LEVEL_MODERATE]
		EC.next_event_time = world.time + 1 MINUTES
		return kill()

	var/successSpawn = create_bingle_lord()
	if(!successSpawn)
		log_and_message_admins("Warning: Could not spawn any mobs for event Bingles")
		return kill()

/datum/event/bingles/proc/create_bingle_lord()
	var/mob/living/simple_animal/hostile/bingle/lord/spawn_bingle = /mob/living/simple_animal/hostile/bingle/lord
	var/list/candidates = SSghost_spawns.poll_candidates("Вы хотите занять роль Лорда Бинглов?", ROLE_BINGLE, TRUE, 30 SECONDS, source = spawn_bingle)
	if(!length(candidates))
		message_admins("Warning: No player volunteered to be a bingle lord!")
		return FALSE

	var/mob/candidate = pick_n_take(candidates)
	var/turf/spawn_loc = pick(GLOB.xeno_spawn)
	spawn_bingle = new(spawn_loc)
	spawn_bingle.possess_by_player(candidate.key)
	spawn_bingle.add_datum_if_not_exist()
	log_and_message_admins("[spawn_bingle.key] has been made into a [spawn_bingle] by an event.")
	return TRUE

#undef BINGLES_MINPLAYERS_TRIGGER
