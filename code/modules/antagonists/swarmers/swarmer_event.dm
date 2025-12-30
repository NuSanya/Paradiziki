/// Minimum amount of players required to start this event
#define SWARMERS_MINPLAYERS_TRIGGER 0
/// Amount of swarmers spawned
#define SWARMERS_SPAWN_AMOUNT 1

/datum/event/swarmers
	/// Type of swarmers being spawned
	var/spawn_type = /mob/living/simple_animal/hostile/swarmer/basic
	/// The pod sent to the station
	var/obj/structure/closet/supplypod/swarmer/pod = null
	/// Candidates for swarmers, saved for pod handling
	var/list/candidates

/datum/event/swarmers/start()
	// It is necessary to wrap this to avoid the event triggering repeatedly.
	INVOKE_ASYNC(src, PROC_REF(wrapped_start))

/datum/event/swarmers/proc/wrapped_start()
	// Reroll event if not enought players
	var/player_count = num_station_players()
	if(player_count < SWARMERS_MINPLAYERS_TRIGGER)
		log_and_message_admins("Random event attempted to spawn swarmers, but there were only [player_count]/[SWARMERS_MINPLAYERS_TRIGGER] players.")
		var/datum/event_container/EC = SSevents.event_containers[EVENT_LEVEL_MODERATE]
		EC.next_event_time = world.time + 1 MINUTES
		return kill()

	var/successSpawn = create_swarmers()
	if(!successSpawn)
		log_and_message_admins("Warning: Could not spawn any mobs for event Swarmers")
		return kill()

/**
 * Gets all candidates for swarmer role, afterwards
 * sends a pod, which will spawn swarmers and the core on landing.
 */
/datum/event/swarmers/proc/create_swarmers()
	var/mob/living/simple_animal/hostile/swarmer/swarmer_type = spawn_type // for source variable
	candidates = SSghost_spawns.poll_candidates("Вы хотите занять роль Свармеров?", ROLE_SWARMER, TRUE, 5 SECONDS, source = swarmer_type)
	if(length(candidates) < SWARMERS_SPAWN_AMOUNT)
		message_admins("Warning: not enough players volunteered to be swarmers. Only [length(candidates)] out of [SWARMERS_SPAWN_AMOUNT]!")
		return FALSE

	initialize_pod()
	return TRUE

/// Creates a pod, registers needed signals and sends it to the station.
/datum/event/swarmers/proc/initialize_pod()
	pod = new
	RegisterSignal(pod, COMSIG_SUPPLYPOD_OPENED, PROC_REF(on_pod_open))
	RegisterSignal(pod, COMSIG_QDELETING, PROC_REF(on_pod_qdel))

	var/turf/target_turf = pick(GLOB.xeno_spawn) // nuSanya change later
	new /obj/effect/pod_landingzone(target_turf, pod)
	notify_ghosts(
		title = "Запущена капсула",
		message = "На станцию запущена капсула Свармеров.",
		source = pod,
	)

/// Spawns the core and event swarmers nearby.
/datum/event/swarmers/proc/on_pod_open()
	SIGNAL_HANDLER
	var/turf/pod_turf = get_turf(pod)
	new /obj/structure/swarmer/core(pod_turf)

	for(var/i in 1 to SWARMERS_SPAWN_AMOUNT)
		var/turf/swarmer_turf = get_step(pod_turf, GLOB.alldirs)
		var/mob/dead/observer/candidate = pick_n_take(candidates)
		var/mob/living/simple_animal/hostile/swarmer/swarmer = new spawn_type(swarmer_turf)
		swarmer.possess_by_player(candidate.key)
		swarmer.add_datum_if_not_exist()
		log_game("[swarmer.key] has become [swarmer].")

/// Cleans up signals and stuff
/datum/event/swarmers/proc/on_pod_qdel()
	SIGNAL_HANDLER
	UnregisterSignal(pod, list(COMSIG_SUPPLYPOD_OPENED, COMSIG_QDELETING))
	pod = null

#undef SWARMERS_MINPLAYERS_TRIGGER
#undef SWARMERS_SPAWN_AMOUNT
