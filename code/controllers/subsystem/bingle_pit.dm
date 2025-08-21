SUBSYSTEM_DEF(bingle_pit) //snowflake because we are doing obj/stru.... instead of datum
	name = "Bingle Pit Processing"
	priority = FIRE_PRIORITY_PROCESS
	flags = SS_BACKGROUND|SS_POST_FIRE_TIMING|SS_NO_INIT
	wait = 2
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	ss_id = "processing"

	var/stat_tag = "BP" //Used for logging
	var/list/obj/structure/bingle_hole/bingle_holes = list()
	var/list/currentrun = list()


/datum/controller/subsystem/bingle_pit/stat_entry(msg)
	msg = "[stat_tag]:[length(bingle_holes)]"
	return ..()

/datum/controller/subsystem/bingle_pit/fire(resumed = FALSE)
	if (!resumed)
		currentrun = bingle_holes.Copy()
	//cache for sanic speed (lists are references anyways)
	var/list/current_run = currentrun

	while(current_run.len)
		var/obj/structure/bingle_hole/hole = current_run[current_run.len]
		current_run.len--
		if(QDELETED(hole))
			bingle_holes -= hole
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/bingle_pit/proc/add_bingle_hole(obj/structure/bingle_hole/hole)
	bingle_holes += hole

/datum/controller/subsystem/bingle_pit/proc/remove_bingle_hole(obj/structure/bingle_hole/hole)
	bingle_holes -= hole
	currentrun -= hole
