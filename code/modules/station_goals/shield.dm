#define MIN_ZOOM 1
#define MAX_ZOOM 8
#define MIN_TAB_INDEX 0
#define MAX_TAB_INDEX 1
GLOBAL_LIST_INIT(meteor_shields, list())
GLOBAL_LIST_EMPTY_TYPED(meteor_shielded_turfs, /turf)

// Щиты станции
// Цепь спутников, окружающих станцию
// Спутники активируются, создавая щит, который будет препятствовать прохождению неорганической материи.
/datum/station_goal/station_shield
	name = "Station Shield"
	var/coverage_goal = 75
	var/last_coverage = 0
	var/is_testing = FALSE
	var/thrown = 0
	var/list/defended = list()
	var/list/collisions = list()

/datum/station_goal/station_shield/get_report()
	return {"<b>Сооружение щитов станции</b><br>
	В области вокруг станции большое количество космического мусора. У нас есть прототип щитовой системы, которую вы должны установить для уменьшения числа происшествий, связанных со столкновениями.
	<br><br>
	Вы можете заказать доставку спутников и системы их управления через шаттл отдела снабжения."}

/datum/station_goal/station_shield/on_report()
	//Unlock
	var/datum/supply_packs/P = SSshuttle.supply_packs["[/datum/supply_packs/misc/station_goal/shield_sat]"]
	P.special_enabled = TRUE
	supply_list.Add(P)

	P = SSshuttle.supply_packs["[/datum/supply_packs/misc/station_goal/shield_sat_control]"]
	P.special_enabled = TRUE
	supply_list.Add(P)
	//Changes
	var/list/station_levels = levels_by_trait(STATION_LEVEL) //change
	coverage_goal = coverage_goal * station_levels.len

/datum/station_goal/station_shield/check_completion()
	if(..())
		return TRUE
	return last_coverage >= coverage_goal

/datum/station_goal/station_shield/proc/update_coverage(success, turf/where)
	if(success)
		defended += list(list("x" = where.x, "y" = where.y))
	else
		collisions += list(list("x" = where.x, "y" = where.y))
	if(length(defended) > last_coverage)
		last_coverage = length(defended)
	if(length(defended) + length(collisions) >= 100)
		last_coverage = length(defended)
		is_testing = FALSE

/datum/station_goal/station_shield/proc/simulate_meteors()
	if(is_testing)
		return FALSE
	is_testing = TRUE
	thrown = 0
	defended = list()
	collisions = list()
	START_PROCESSING(SSprocessing, src)

/datum/station_goal/station_shield/process()
	spawn_meteor(list(/obj/effect/meteor/fake = 1))
	thrown++
	if(thrown >= 100)
		return PROCESS_KILL

/obj/item/circuitboard/computer/sat_control
	board_name = "Контроллер сети спутников"
	build_path = /obj/machinery/computer/sat_control
	origin_tech = "engineering=3"

/obj/machinery/computer/sat_control
	name = "Управление спутниками"
	desc = "Используется для управления спутниковой сетью."
	circuit = /obj/item/circuitboard/computer/sat_control
	icon_screen = "accelerator"
	icon_keyboard = "accelerator_key"
	/// A notice to display to the user.
	var/notice = ""
	/// The color to use for the notice.
	var/notice_color = "white"
	/// Before world.time reaches this, the notice will not automatically update to show the testing status.
	var/freeze_notice_until = 0
	/// The X offset of the UI map
	var/offset_x = 0
	/// The Y offset of the UI map
	var/offset_y = 0
	/// The zoom of the UI map
	var/zoom = 1
	/// The ID of the currently opened UI tab
	var/tab_index = 0

/obj/machinery/computer/sat_control/attack_hand(mob/user)
	if(..())
		return TRUE
	ui_interact(user)

/obj/machinery/computer/sat_control/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SatelliteControl", name)
		ui.open()

/obj/machinery/computer/sat_control/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/sat_control/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SatelliteControl", name)
		ui.open()

/obj/machinery/computer/sat_control/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/nanomaps)
	)

/obj/machinery/computer/sat_control/ui_data(mob/user)
	var/list/data = list()

	data["satellites"] = list()
	for(var/obj/machinery/satellite/S in GLOB.machines)
		data["satellites"] += list(list(
			"id" = S.id,
			"active" = S.active,
			"mode" = S.mode,
			"x" = S.x,
			"y" = S.y
		))
	update_notice()
	data["notice"] = notice
	data["notice_color"] = notice_color
	data["zoom"] = zoom
	data["offsetX"] = offset_x
	data["offsetY"] = offset_y
	data["tabIndex"] = tab_index

	var/datum/station_goal/station_shield/G = locate() in SSticker.mode?.station_goals
	if(G)
		data["has_goal"] = 1
		data["coverage"] = G.last_coverage
		data["coverage_goal"] = G.coverage_goal
		data["testing"] = G.is_testing
		data["thrown"] = G.thrown
		data["defended"] = G.defended
		data["collisions"] = G.collisions
		var/list/fake_meteors = list()
		if(G.is_testing)
			for(var/obj/effect/meteor/fake/meteor in GLOB.meteor_list)
				fake_meteors += list(list("x" = meteor.x, "y" = meteor.y))
		data["fake_meteors"] = fake_meteors
	return data

/obj/machinery/computer/sat_control/ui_act(action, params)
	if(..())
		return

	switch(action)
		if("begin_test")
			var/datum/station_goal/station_shield/G = locate() in SSticker.mode?.station_goals
			if(G)
				G.simulate_meteors()
		if("toggle")
			toggle(text2num(params["id"]))
			. = TRUE
		if("set_tab_index")
			var/new_tab_index = text2num(params["tab_index"])
			if(isnull(new_tab_index) || new_tab_index < MIN_TAB_INDEX || new_tab_index > MAX_TAB_INDEX)
				return
			tab_index = new_tab_index
		if("set_zoom")
			var/new_zoom = text2num(params["zoom"])
			if(isnull(new_zoom) || new_zoom < MIN_ZOOM || new_zoom > MAX_ZOOM)
				return
			zoom = new_zoom
		if("set_offset")
			var/new_offset_x = text2num(params["offset_x"])
			var/new_offset_y = text2num(params["offset_y"])
			if(isnull(new_offset_x) || isnull(new_offset_y))
				return
			offset_x = new_offset_x
			offset_y = new_offset_y

/obj/machinery/computer/sat_control/proc/toggle(id)
	for(var/obj/machinery/satellite/S in GLOB.machines)
		if(S.id == id)
			if(!S.toggle())
				notice = "Вы можете активировать только те спутники, что находятся в космосе"
				notice_color = "red"
				freeze_notice_until = world.time + 5 SECONDS

/obj/machinery/computer/sat_control/proc/update_notice()
	var/datum/station_goal/station_shield/G = locate() in SSticker.mode?.station_goals
	if(!G)
		return
	if(freeze_notice_until >= world.time)
		return

	if(G.is_testing && G.thrown < 100)
		notice = "Симулируем броски метеоров ([G.thrown]/100)..."
		notice_color = "white"
		return

	var/total_meteors = length(G.defended) + length(G.collisions)
	if(total_meteors == 0)
		notice = "Проверка не запущена."
		notice_color = "red"
		return

	if(G.is_testing)
		notice = "Заканчивается симулирование ([total_meteors]/100)..."
		notice_color = "white"
		return

	notice = "Проверка завершена. [100 - G.last_coverage] столкновений из 100 метеоров."
	notice_color = (G.last_coverage > G.coverage_goal) ? "blue" : "red"


/obj/machinery/satellite
	name = "Недействующий спутник"
	desc = ""
	icon = 'icons/obj/machines/satellite.dmi'
	icon_state = "sat_inactive"
	density = TRUE
	use_power = FALSE
	var/mode = "NTPROBEV0.8"
	var/active = FALSE
	/// global counter of IDs
	var/static/global_id = 0
	/// id number for this satellite
	var/id = 0
	/// toggle cooldown
	COOLDOWN_DECLARE(toggle_sat_cooldown)

/obj/machinery/satellite/Initialize(mapload)
	. = ..()
	id = global_id++

/obj/machinery/satellite/attack_hand(mob/user)
	if(..())
		return TRUE
	interact(user)

/obj/machinery/satellite/interact(mob/user)
	toggle(user)

/obj/machinery/satellite/proc/toggle(mob/user)
	if(!COOLDOWN_FINISHED(src, toggle_sat_cooldown))
		return FALSE
	if(!active && !isinspace())
		if(user)
			to_chat(user, span_warning("Вы можете активировать только находящиеся в космосе спутники."))
		return FALSE
	if(user)
		to_chat(user, span_notice("Вы [active ? "деактивировали": "активировали"] [src]"))
	active = !active
	COOLDOWN_START(src, toggle_sat_cooldown, 1 SECONDS)
	if(active)
		set_anchored(TRUE)
		pulledby?.stop_pulling()
		animate(src, pixel_y = 2, time = 10, loop = -1)
	else
		animate(src, pixel_y = 0, time = 10)
		set_anchored(FALSE)
	update_icon(UPDATE_ICON_STATE)
	return TRUE

/obj/machinery/satellite/update_icon_state()
	icon_state = active ? "sat_active" : "sat_inactive"

/obj/machinery/satellite/multitool_act(mob/living/user, obj/item/I)
	..()
	add_fingerprint(user)
	to_chat(user, span_notice("// NTSAT-[id] // Режим : [active ? "ОСНОВНОЙ" : "ОЖИДАНИЕ"] //[emagged ? "ОТЛАДКА //" : ""]"))
	return TRUE

/obj/machinery/satellite/meteor_shield
	name = "Спутник метеорного щита"
	desc = "Узловой спутник метеорной защиты"
	mode = "M-SHIELD"
	speed_process = TRUE
	var/kill_range = 14
	/// A list of "proxy" objects used for multi-z coverage.
	var/list/obj/effect/abstract/meteor_shield_proxy/proxies = list()

/obj/machinery/satellite/meteor_shield/proc/space_los(meteor)
	for(var/turf/T in get_line(src,meteor))
		if(!isspaceturf(T))
			return FALSE
	return TRUE

/obj/machinery/satellite/meteor_shield/examine(mob/user)
	. = ..()
	if(active)
		. += span_notice("В настоящее время он активен. Вы можете взаимодействовать с ним, чтобы отключить.")
		if(emagged)
			. += span_warning("Вместо обычных звуков писков и пингов, он издаёт странное и постоянное шипение белого шума…")
		else
			. += span_notice("Он периодически издаёт писки и пинги, связываясь с сетью спутников.")
	else
		. += span_notice("В настоящее время он отключен. Вы можете взаимодействовать с ним, чтобы включить.")
		if(emagged)
			. += span_warning("Но что-то здесь не так...?")

/obj/machinery/satellite/meteor_shield/Initialize(mapload)
	. = ..()
	GLOB.meteor_shields += src
	setup_proxies()

/obj/machinery/satellite/meteor_shield/Destroy()
	. = ..()
	if(active && emagged)
		change_meteor_chance(0.5)
	GLOB.meteor_shields -= src

/obj/machinery/satellite/meteor_shield/process()
	if(!active)
		return
	for(var/obj/effect/M in GLOB.meteor_list)
		if(M.z != z)
			continue
		if(get_dist(M, src) > kill_range)
			continue
		if(!emagged && space_los(M))
			if(!istype(M, /obj/effect/meteor/fake))
				Beam(get_turf(M), icon_state = "sat_beam", time = 5, maxdistance = kill_range)
				if(istype(M, /obj/effect/meteor/gore))
					new /obj/item/reagent_containers/food/snacks/meatsteak(get_turf(M))
			qdel(M)

/obj/machinery/satellite/meteor_shield/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents)
	. = ..()
	setup_proxies()

/obj/machinery/satellite/meteor_shield/proc/setup_proxies()
	for(var/stacked_z in SSmapping.get_connected_levels(get_turf(src)))
		setup_proxy_for_z(stacked_z)

/obj/machinery/satellite/meteor_shield/proc/setup_proxy_for_z(target_z)
	if(target_z == z)
		return
	// don't setup a proxy if there already is one.
	if(!QDELETED(proxies["[target_z]"]))
		return
	var/turf/our_loc = get_turf(src)
	var/turf/target_loc = locate(our_loc.x, our_loc.y, target_z)
	if(QDELETED(target_loc))
		return
	var/obj/effect/abstract/meteor_shield_proxy/new_proxy = new(target_loc, src)
	proxies["[target_z]"] = new_proxy

/obj/machinery/satellite/meteor_shield/Process_Spacemove(movement_dir = NONE, continuous_move = FALSE)
	if(active)
		return TRUE
	return ..()

/obj/machinery/satellite/meteor_shield/toggle(user)
	if(..(user))
		return TRUE
	if(emagged)
		if(active)
			change_meteor_chance(2)
		else
			change_meteor_chance(0.5)

/obj/machinery/satellite/meteor_shield/proc/change_meteor_chance(mod = 1)
	var/static/list/meteor_event_typecache
	if(!meteor_event_typecache)
		meteor_event_typecache = typecacheof(list(
			/datum/event/meteor_wave,
			/datum/event/dust/meaty,
			/datum/event/dust,
		))
	for(var/datum/event_container/container in SSevents.event_containers)
		for(var/datum/event_meta/M in container.available_events)
			if(is_type_in_typecache(M.event_type, meteor_event_typecache))
				M.weight_mod *= mod

/obj/machinery/satellite/meteor_shield/emag_act(mob/user)
	if(emagged)
		return
	add_attack_logs(user, src, "emagged")
	if(user)
		to_chat(user, span_danger("Вы переписали схемы метеорного щита, заставив его привлекать метеоры, а не уничтожать их."))
	emagged = TRUE
	if(active)
		change_meteor_chance(2)


/obj/effect/abstract/meteor_shield_proxy
	name = "Proxy Detector For Meteor Shield"
	/// The meteor shield sat this is proxying.
	var/obj/machinery/satellite/meteor_shield/parent

/obj/effect/abstract/meteor_shield_proxy/Initialize(mapload, obj/machinery/satellite/meteor_shield/parent)
	. = ..()
	if(QDELETED(parent))
		return INITIALIZE_HINT_QDEL
	src.parent = parent
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_parent_deleted))
	RegisterSignal(parent, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_parent_z_changed))
	RegisterSignal(parent, COMSIG_QDELETING, PROC_REF(on_parent_moved))


/obj/effect/abstract/meteor_shield_proxy/proc/on_parent_moved()
	SIGNAL_HANDLER
	var/turf/parent_loc = get_turf(parent)
	var/turf/new_loc = locate(parent_loc.x, parent_loc.y, z)
	abstract_move(new_loc)

/obj/effect/abstract/meteor_shield_proxy/proc/on_parent_z_changed()
	SIGNAL_HANDLER
	if(z == parent.z || !are_zs_connected(parent, src))
		qdel(src)

/obj/effect/abstract/meteor_shield_proxy/proc/on_parent_deleted()
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/abstract/meteor_shield_proxy/proc/space_los(meteor)
	for(var/turf/T in get_line(src,meteor))
		if(!isspaceturf(T))
			return FALSE
	return TRUE

/obj/effect/abstract/meteor_shield_proxy/process()
	if(!parent.active)
		return
	for(var/obj/effect/M in GLOB.meteor_list)
		if(M.z != z)
			continue
		if(get_dist(M, src) > parent.kill_range)
			continue
		if(!parent.emagged && space_los(M))
			if(!istype(M, /obj/effect/meteor/fake))
				Beam(get_turf(M), icon_state = "sat_beam", time = 5, maxdistance = parent.kill_range)
				if(istype(M, /obj/effect/meteor/gore))
					new /obj/item/reagent_containers/food/snacks/meatsteak(get_turf(M))
			qdel(M)

#undef MIN_ZOOM
#undef MAX_ZOOM
#undef MIN_TAB_INDEX
#undef MAX_TAB_INDEX
