// TODO: move to spell actions once they are done

/datum/action/cooldown/bingle
	name = "Бингл что-то"
	desc = "Напишите баг-репорт, если увидели это."
	button_icon = 'icons/mob/bingle/binglepit.dmi'

/datum/action/cooldown/bingle/IsAvailable(feedback = FALSE)
	if(!isbingle(owner))
		return FALSE
	return ..()

/datum/action/cooldown/bingle/create_hole
	name = "Create Bingle Pit"
	desc = "Единожды создаёт яму."
	button_icon_state = "binglepit"
	/// How long does it take to create a hole
	var/creation_time = 5 SECONDS
	/// The hole that we are creating
	var/obj/structure/bingle_hole/hole

/datum/action/cooldown/bingle/create_hole/Activate()
	. = ..()
	var/mob/living/user = owner
	var/turf/our_turf = get_turf(user)
	if(isspaceturf(our_turf))
		user.balloon_alert(user, "невозможно в космосе!")
		return
	if(!is_station_level(our_turf.z))
		user.balloon_alert(user, "вне станции!")
		return
	if(!check_hole_spawn(our_turf))
		user.balloon_alert(user, "нет места!")
		return
	if(!do_after(user, creation_time, user, max_interact_count = 1, cancel_on_max = TRUE))
		user.balloon_alert(user, "прервано!")
		return
	user.balloon_alert(user, "яма создана")
	INVOKE_ASYNC(src, PROC_REF(spawn_hole), our_turf)
	qdel(src)

/// Used to check if we have any dense turfs nearby
/datum/action/cooldown/bingle/create_hole/proc/check_hole_spawn(turf/selected_turf)
	for(var/turf/adjacent_turf as anything in RANGE_TURFS(1, selected_turf))
		if(isnull(adjacent_turf) || adjacent_turf.density)
			return FALSE
	return TRUE

/// Proc used to spawn the hole itself
/datum/action/cooldown/bingle/create_hole/proc/spawn_hole(turf/selected_turf)
	var/datum/antagonist/bingle/bingle_datum = owner.mind?.has_antag_datum(/datum/antagonist/bingle)
	if(!bingle_datum)
		return

	var/obj/structure/bingle_hole/hole = new(selected_turf)
	// Complete the bingle lord objective
	var/datum/objective/bingle_lord/lord_obj = bingle_datum.objectives[1]
	lord_obj.completed = TRUE
	// Register the pit in the team, give the second obj to the bingle lord
	var/datum/team/bingles/bingle_team = bingle_datum.get_team()
	bingle_team.pit_check = hole
	bingle_datum.give_objectives()
	// Register the team in the pit
	hole.bingle_team = bingle_datum.get_team()
	qdel(src)
