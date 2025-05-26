//Station Shield
// A chain of satellites encircles the station
// Satellites be actived to generate a shield that will block unorganic matter from passing it.
/datum/station_goal/station_shield
	name = "Station Shield"
	var/max_meteor = 100
	var/coverage_goal = 75
	var/last_coverage = 0
	var/is_testing = FALSE
	var/thrown = 0
	var/goal_completed = FALSE
	var/list/defended = list()
	var/list/collisions = list()

/datum/station_goal/station_shield/get_report()
	return {"<b>Station Shield construction</b><br>
	The station is located in a zone full of space debris. We have a prototype shielding system you will deploy to reduce collision related accidents.
	<br><br>
	You can order the satellites and control systems through the cargo shuttle."}

/datum/station_goal/station_shield/on_report()
	//Unlock
	var/datum/supply_packs/P = SSshuttle.supply_packs["[/datum/supply_packs/misc/station_goal/shield_sat]"]
	P.special_enabled = TRUE
	supply_list.Add(P)

	P = SSshuttle.supply_packs["[/datum/supply_packs/misc/station_goal/shield_sat_control]"]
	P.special_enabled = TRUE
	supply_list.Add(P)
	//Changes
	var/list/station_levels = levels_by_trait(STATION_LEVEL)
	coverage_goal = coverage_goal * station_levels.len
	max_meteor = max_meteor * station_levels.len

/datum/station_goal/station_shield/check_completion()
	if(..())
		return TRUE
	return goal_completed

/datum/station_goal/station_shield/proc/update_coverage(success, turf/where)
	if(success)
		defended += list(list("x" = where.x, "y" = where.y, "z" = where.z))
	else
		collisions += list(list("x" = where.x, "y" = where.y, "z" = where.z))
	if(length(defended) > last_coverage)
		last_coverage = length(defended)
	if(length(defended) + length(collisions) >= max_meteor)
		last_coverage = length(defended)
		is_testing = FALSE

/datum/station_goal/station_shield/proc/simulate_meteors()
	if(is_testing)
		return FALSE
	if(last_coverage >= coverage_goal)
		goal_completed = TRUE
	last_coverage = 0
	is_testing = TRUE
	thrown = 0
	defended = list()
	collisions = list()
	START_PROCESSING(SSprocessing, src)

/datum/station_goal/station_shield/process()
	spawn_meteor(list(/obj/effect/meteor/fake = 1))
	thrown++
	if(thrown >= max_meteor)
		if(last_coverage >= coverage_goal)
			goal_completed = TRUE
		return PROCESS_KILL

/obj/item/circuitboard/computer/sat_control
	board_name = "Satellite Network Control"
	build_path = /obj/machinery/computer/sat_control
	origin_tech = "engineering=3"

/obj/machinery/computer/sat_control
	name = "Satellite Control"
	desc = "Используется для управления спутниковой сетью."
	circuit = /obj/item/circuitboard/computer/sat_control
	icon_screen = "accelerator"
	icon_keyboard = "rd_key"
	var/datum/ui_module/sat_control/sat_control

/obj/machinery/computer/sat_control/New()
	sat_control = new(src)
	sat_control.object = src
	..()

/obj/machinery/computer/sat_control/Destroy()
	QDEL_NULL(sat_control)
	return ..()

/obj/machinery/computer/sat_control/attack_hand(mob/user)
	if(stat & (BROKEN|NOPOWER))
		return

	if(..())
		return TRUE

	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/computer/sat_control/attack_ai(mob/user)
	attack_hand(user)

/obj/machinery/computer/sat_control/ui_interact(mob/user, datum/tgui/ui = null)
	sat_control.ui_interact(user, ui)

/obj/machinery/computer/sat_control/interact(mob/user)
	sat_control.ui_interact(user)

/obj/machinery/satellite
	name = "Defunct Satellite"
	desc = ""
	icon = 'icons/obj/machines/satellite.dmi'
	icon_state = "sat_inactive"
	var/mode = "NTPROBEV0.8"
	var/active = FALSE
	density = TRUE
	use_power = FALSE
	var/static/gid = 1
	var/id = 0

/obj/machinery/satellite/Initialize(mapload)
	. = ..()
	id = gid++

/obj/machinery/satellite/attack_hand(mob/user)
	if(..())
		return 1
	interact(user)

/obj/machinery/satellite/interact(mob/user)
	toggle(user)

/obj/machinery/satellite/proc/toggle(mob/user)
	if(!active && !isinspace())
		if(user)
			to_chat(user, "<span class='warning'>You can only activate satellites which are in space.</span>")
		return FALSE
	if(user)
		to_chat(user, "<span class='notice'>You [active ? "deactivate": "activate"] [src]</span>")
	active = !active
	if(active)
		animate(src, pixel_y = 2, time = 10, loop = -1)
		anchored = TRUE
	else
		animate(src, pixel_y = 0, time = 10)
		anchored = FALSE
	update_icon(UPDATE_ICON_STATE)
	return TRUE

/obj/machinery/satellite/update_icon_state()
	icon_state = active ? "sat_active" : "sat_inactive"

/obj/machinery/satellite/multitool_act(mob/living/user, obj/item/I)
	to_chat(user, "<span class='notice'>// NTSAT-[id] // Mode : [active ? "PRIMARY" : "STANDBY"] //[emagged ? "DEBUG_MODE //" : ""]</span>")

/obj/machinery/satellite/meteor_shield
	name = "Meteor Shield Satellite"
	desc = "Meteor Point Defense Satellite."
	mode = "M-SHIELD"
	speed_process = TRUE
	var/kill_range = 14

/obj/machinery/satellite/meteor_shield/proc/space_los(meteor)
	for(var/turf/T in get_line(src,meteor))
		if(!isspaceturf(T))
			return FALSE
	return TRUE

/obj/machinery/satellite/meteor_shield/process()
	if(!active)
		return
	for(var/obj/effect/M in GLOB.meteor_list)
		if(M.z != z)
			continue
		if(get_dist(M, src) > kill_range)
			continue
		var/is_fake = istype(M, /obj/effect/meteor/fake)
		if((!emagged || is_fake) && space_los(M))
			if(!is_fake)
				Beam(get_turf(M), icon_state = "sat_beam", time = 5, maxdistance = kill_range)
				new /obj/effect/temp_visual/explosion(get_turf(M))
				if(istype(M, /obj/effect/meteor/gore))
					new /obj/item/reagent_containers/food/snacks/meatsteak(get_turf(M))
			qdel(M)

/obj/machinery/satellite/meteor_shield/toggle(user)
	if(..(user))
		return TRUE
	if(emagged)
		if(active)
			change_meteor_chance(2)
		else
			change_meteor_chance(0.5)

/obj/machinery/satellite/meteor_shield/proc/change_meteor_chance(mod)
	for(var/datum/event_container/container in SSevents.event_containers)
		for(var/datum/event_meta/M in container.available_events)
			if(M.event_type == /datum/event/meteor_wave)
				M.weight_mod *= mod

/obj/machinery/satellite/meteor_shield/Destroy()
	. = ..()
	if(active && emagged)
		change_meteor_chance(0.5)

/obj/machinery/satellite/meteor_shield/emag_act(mob/user)
	if(!emagged)
		to_chat(user, "<span class='danger'>You override the shield's circuits, causing it to attract meteors instead of destroying them.</span>")
		emagged = TRUE
		if(active)
			change_meteor_chance(2)
		return TRUE
