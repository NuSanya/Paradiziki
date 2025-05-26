#define MIN_ZOOM 1
#define MAX_ZOOM 8
#define MIN_TAB_INDEX 0
#define MAX_TAB_INDEX 1

/datum/ui_module/sat_control
	name = "Управление спутниками"
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
	/// What are we in
	var/obj/object

/datum/ui_module/sat_control/ui_state(mob/user)
	return GLOB.default_state

/datum/ui_module/sat_control/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SatelliteControl", name)
		ui.open()

/datum/ui_module/sat_control/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/nanomaps)
	)

/datum/ui_module/sat_control/ui_data(mob/user)
	var/list/data = list()

	data["satellites"] = list()
	for(var/obj/machinery/satellite/S in GLOB.machines)
		var/turf/T = get_turf(S)
		data["satellites"] += list(list(
			"id" = S.id,
			"active" = S.active,
			"mode" = S.mode,
			"x" = T.x,
			"y" = T.y,
			"z" = T.z,
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
		data["coverage"] = G.last_coverage
		data["coverage_goal"] = G.coverage_goal
		data["max_meteor"] = G.max_meteor
		data["testing"] = G.is_testing
		data["thrown"] = G.thrown
		data["defended"] = G.defended
		data["collisions"] = G.collisions
		var/list/fake_meteors = list()
		if(G.is_testing)
			for(var/obj/effect/meteor/fake/meteor in GLOB.meteor_list)
				fake_meteors += list(list("x" = meteor.x, "y" = meteor.y, "z" = meteor.z))
		data["fake_meteors"] = fake_meteors
	data["has_goal"] = !!G
	return data

/datum/ui_module/sat_control/ui_static_data(mob/user)
	var/list/static_data = list()
	var/list/station_level_numbers = list()
	var/list/station_level_names = list()
	for(var/z_level in levels_by_trait(STATION_LEVEL))
		station_level_numbers += z_level
		station_level_names += check_level_trait(z_level, STATION_LEVEL)
	static_data["stationLevelNum"] = station_level_numbers
	static_data["stationLevelName"] = station_level_names
	return static_data

/datum/ui_module/sat_control/ui_act(action, params)
	if(..())
		return

	switch(action)
		if("begin_test")
			var/datum/station_goal/station_shield/G = locate() in SSticker.mode?.station_goals
			if(G)
				G.simulate_meteors()
		if("toggle")
			toggle(params["id"])
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

/datum/ui_module/sat_control/proc/toggle(id)
	var/num_id = text2num(id)
	for(var/obj/machinery/satellite/S in GLOB.machines)
		if(S.id == num_id && are_zs_connected(object, S))
			if(!S.toggle())
				notice = "Вы можете активировать только находящиеся в космосе спутники."
				notice_color = "red"
				freeze_notice_until = world.time + 5 SECONDS

/datum/ui_module/sat_control/proc/update_notice()
	var/datum/station_goal/station_shield/G = locate() in SSticker.mode?.station_goals
	if(!G)
		return
	if(freeze_notice_until >= world.time)
		return

	if(G.is_testing && G.thrown < G.max_meteor)
		notice = "Идёт симуляция метеоритного шторма ([G.thrown]/[G.max_meteor])..."
		notice_color = "white"
		return

	var/total_meteors = length(G.defended) + length(G.collisions)
	if(total_meteors == 0)
		notice = "Симуляция не активирована."
		notice_color = "red"
		return

	if(G.is_testing)
		notice = "Завершение симуляции метеоритного шторма ([total_meteors]/[G.max_meteor])..."
		notice_color = "white"
		return

	notice = "Симуляция завершена. [G.max_meteor - G.last_coverage] столкновений из [G.max_meteor] метеоров. [G.goal_completed ? ((G.last_coverage > G.coverage_goal) ? "Цель выполнена." : "Цель выполнена, но текущая симуляция провалена.") : "Симуляция провалена."]"
	notice_color = (G.last_coverage > G.coverage_goal) ? "blue" : "red"

#undef MIN_ZOOM
#undef MAX_ZOOM
#undef MIN_TAB_INDEX
#undef MAX_TAB_INDEX
