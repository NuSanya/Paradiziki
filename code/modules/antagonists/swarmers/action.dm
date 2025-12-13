/datum/action/innate/swarmer
	name = "Свармер что-то"
	desc = "Напишите баг-репорт, если увидели это."
	button_icon = 'icons/mob/actions/actions_swarmer.dmi'

/datum/action/innate/swarmer/IsAvailable(feedback = FALSE)
	if(!isswarmer(owner))
		return FALSE
	return ..()

/datum/action/innate/swarmer/build
	name = "Создать что-то"
	/// What do we build
	var/build_type = /obj/structure/swarmer
	/// How many resources does it cost to build it
	var/build_cost = 0
	/// How long does it take to build
	var/build_time = 0
	/// Does it require the user to type a keyword for the structure
	var/req_keyword = FALSE

/// Updates description to include material cost.
/datum/action/innate/swarmer/build/update_button_name(atom/movable/screen/movable/action_button/button, force)
	. = ..()
	desc = "[initial(desc)] Стоимость: [build_cost] металлических материалов."

/datum/action/innate/swarmer/build/Activate()
	var/mob/living/user = owner
	var/turf/our_turf = get_turf(user)
	if(isspaceturf(our_turf))
		user.balloon_alert(user, "тут космос!")
		return
	if(!is_station_level(our_turf.z))
		user.balloon_alert(user, "вне станции!")
		return
	if((locate(/obj/structure/swarmer) in our_turf))
		user.balloon_alert(user, "нельзя строить сверху существующего!")
		return
	if((locate(/obj/machinery/porta_turret/swarmer) in our_turf))
		user.balloon_alert(user, "нельзя строить сверху существующего!")
		return
	if(!do_after(user, build_time, user, max_interact_count = 1))
		user.balloon_alert(user, "сбито!")
		return
	if(!adjust_swarmer_metallic_resources(-build_cost))
		user.balloon_alert(user, "недостаточно ресурсов!")
		return
	user.balloon_alert(user, "успех!")
	return new build_type(our_turf)

/datum/action/innate/swarmer/build/barricade
	name = "Создать баррикаду"
	desc = "Создаёт баррикаду, через которую могут проходить \"Свармеры\", и пролетать их лазеры."
	button_icon_state = "swarmer_barricade"
	build_type = /obj/structure/swarmer/blockade
	build_cost = SWARMER_BLOCKADE_COST
	build_time = SWARMER_FAST_BUILD_DELAY

/datum/action/innate/swarmer/build/trap
	name = "Создать ловушку"
	desc = "Создаёт ловушку, которая будет оглушать всех, кроме \"Свармеров\"."
	button_icon_state = "swarmer_trap"
	build_type = /obj/structure/swarmer/trap
	build_cost = SWARMER_TRAP_COST
	build_time = SWARMER_FAST_BUILD_DELAY

/datum/action/innate/swarmer/build/transport_hub
	name = "Создать Хаб"
	desc = "Создаёт Хаб, между которыми смогут перемещаться все \"Свармеры\"."
	button_icon_state = "swarmer_hub"
	build_type = /obj/structure/swarmer/transport_hub
	build_cost = SWARMER_HUB_COST
	build_time = SWARMER_SLOW_BUILD_DELAY

/datum/action/innate/swarmer/build/transport_hub/Activate()
	. = ..() // Returns built hub
	if(!.)
		return
	var/keyword = tgui_input_text(owner, "Пожалуйста, введите название для постройки.", "Ввод названия")
	if(!keyword)
		return
	var/obj/structure/swarmer/transport_hub/hub = .
	hub.listkey = "[keyword] ([hub.listkey])"

/datum/action/innate/swarmer/build/processer
	name = "Создать переработчик органики"
	desc = "Обрабатывает неживую материю."
	button_icon_state = "swarmer_processor"
	build_type = /obj/structure/swarmer/organic_processer
	build_cost = SWARMER_PROCESSER_COST
	build_time = SWARMER_NORMAL_BUILD_DELAY

/datum/action/innate/swarmer/build/analyzer
	name = "Создать анализатор органики"
	desc = "Обрабатывает живую и металлическую материю."
	button_icon_state = "swarmer_analyzer"
	build_type = /obj/structure/swarmer/organic_analyzer
	build_cost = SWARMER_ANALYZER_COST
	build_time = SWARMER_NORMAL_BUILD_DELAY

/datum/action/innate/swarmer/build/repair_station
	name = "Создать станцию починки"
	desc = "Быстрая починка для \"Свармеров\"."
	button_icon_state = "swarmer_repair"
	build_type = /obj/structure/swarmer/repair_station
	build_cost = SWARMER_REPAIR_STATION_COST
	build_time = SWARMER_NORMAL_BUILD_DELAY

/datum/action/innate/swarmer/build/storage
	name = "Создать хранилище для ресурсов"
	desc = "Ускоряет ручной сбор материалов."
	button_icon_state = "swarmer_storage"
	build_type = /obj/structure/swarmer/resource_storage
	build_cost = SWARMER_STORAGE_COST
	build_time = SWARMER_FAST_BUILD_DELAY

/datum/action/innate/swarmer/build/rapid_turret
	name = "Создать штурмовую турель"
	desc = "Турель, стреляющая залпами лучей."
	button_icon_state = "swarmer_rapid_turret"
	build_type = /obj/machinery/porta_turret/swarmer/turret
	build_cost = SWARMER_RAPID_TURRET_COST
	build_time = SWARMER_NORMAL_BUILD_DELAY

/datum/action/innate/swarmer/build/sniper_turret
	name = "Создать снайперскую турель"
	desc = "Турель, стреляющая сильным, пробивающим лучом."
	button_icon_state = "swarmer_sniper_turret"
	build_type = /obj/machinery/porta_turret/swarmer/sniper
	build_cost = SWARMER_SNIPER_TURRET_COST
	build_time = SWARMER_SLOW_BUILD_DELAY

/datum/action/innate/swarmer/build/acp_turret
	name = "Создать установку ACP"
	desc = "Турель, бьющая целей по области, накладывая дебаффы."
	button_icon_state = "swarmer_acp"
	build_type = /obj/structure/swarmer/acp_turret
	build_cost = SWARMER_ACP_COST
	build_time = SWARMER_NORMAL_BUILD_DELAY

/// Action for combat swarmer for projectile mode switching
/datum/action/innate/swarmer/mode_switcher
	name = "Сменить режим стрельбы"
	desc = "Сменяет текущий режим стрельбы на другие доступные."
	button_icon_state = "shoot_mode"
	/// Reference to swarmer's mode datum
	var/datum/swarmer_proj_mode/swarmer_proj_mode

/datum/action/innate/swarmer/mode_switcher/Grant(mob/living/simple_animal/hostile/swarmer/combat/user)
	. = ..()
	swarmer_proj_mode = user.swarmer_proj_mode

/datum/action/innate/swarmer/mode_switcher/Activate()
	var/choice = swarmer_proj_mode.swap_radial_menu_to_path()
	if(!choice)
		return
	if(!do_after(owner, SWARMER_MODE_SWITCH_DELAY, owner, DA_IGNORE_USER_LOC_CHANGE | DA_IGNORE_TARGET_LOC_CHANGE, max_interact_count = 1))
		owner.balloon_alert(owner, "сбито!")
		return
	owner.balloon_alert(owner, "успех!")
	swarmer_proj_mode = new choice
	swarmer_proj_mode.link_mode(owner)
	swarmer_proj_mode.apply_mode()

/datum/action/innate/swarmer/mode_switcher/Remove(mob/user)
	. = ..()
	swarmer_proj_mode = null
