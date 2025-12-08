/datum/action/innate/swarmer
	name = "Свармер что-то"
	desc = "Напишите баг-репорт, если увидели это."

/datum/action/innate/swarmer/IsAvailable()
	if(!isswarmer(owner))
		return FALSE
	return ..()


/datum/action/innate/swarmer/build
	name = "Создать что-то"
	desc = "Напишите баг-репорт, если увидели это."
	/// What do we build
	var/build_type = /obj/structure/swarmer
	/// How many resources does it cost to build it
	var/build_cost = 0
	/// How long does it take to build
	var/build_time = 0
	/// Does it require the user to type a keyword for the structure
	var/req_keyword = FALSE

/datum/action/innate/swarmer/build/Activate()
	var/turf/our_turf = get_turf(owner)
	if(isspaceturf(our_turf))
		owner.balloon_alert(owner, "тут космос!")
		return
	if(!is_level_reachable(our_turf.z))
		owner.balloon_alert(owner, "тут нельзя строить!")
		return
	if(!is_station_level(our_turf.z))
		owner.balloon_alert(owner, "вне станции!")
		return
	if((locate(/obj/structure/swarmer) in our_turf))
		owner.balloon_alert(owner, "нельзя строить сверху существующего!")
		return
	if(!do_after(owner, build_time, owner, max_interact_count = 1, cancel_on_max = TRUE))
		owner.balloon_alert(owner, "сбито!")
		return
	if(!adjust_swarmer_metallic_resources(-build_cost))
		owner.balloon_alert(owner, "недостаточно ресурсов!")
		return
	var/keyword
	if(req_keyword)
		keyword = tgui_input_text(owner, "Пожалуйста, введите название для постройки.", "Ввод названия")
	owner.balloon_alert(owner, "успех!")
	new build_type(our_turf, keyword)

/datum/action/innate/swarmer/build/barricade
	name = "Создать баррикаду"
	desc = "Создаёт баррикаду, через которую могут проходить \"Свармеры\", и пролетать их лазеры."
	build_type = /obj/structure/swarmer/blockade
	build_cost = SWARMER_BLOCKADE_COST
	build_time = SWARMER_BLOCKADE_BUILD_DELAY

/datum/action/innate/swarmer/build/trap
	name = "Создать ловушку"
	desc = "Создаёт ловушку, которая будет оглушать всех, кроме \"Свармеров\"."
	build_type = /obj/structure/swarmer/trap
	build_cost = SWARMER_TRAP_COST
	build_time = SWARMER_TRAP_BUILD_DELAY

/datum/action/innate/swarmer/build/transport_hub
	name = "Создать Хаб"
	desc = "Создаёт Хаб, между которыми смогут перемещаться все \"Свармеры\"."
	build_type = /obj/structure/swarmer/transport_hub
	build_cost = SWARMER_HUB_COST
	build_time = SWARMER_HUB_BUILD_DELAY
	req_keyword = TRUE

/datum/action/innate/swarmer/mode_switcher
	name = "Сменить режим стрельбы"
	desc = "Сменяет текущий режим стрельбы на другие доступные."
	/// Reference to swarmer's mode datum
	var/datum/swarmer_proj_mode/swarmer_proj_mode

/datum/action/innate/swarmer/mode_switcher/Grant(mob/living/simple_animal/hostile/swarmer/combat/user)
	. = ..()
	swarmer_proj_mode = user.swarmer_proj_mode

/datum/action/innate/swarmer/mode_switcher/Activate()
	var/choice = swarmer_proj_mode.swap_radial_menu_to_path()
	if(!choice)
		return
	if(!do_after(owner, SWARMER_MODE_SWITCH_DELAY, owner, max_interact_count = 1, cancel_on_max = TRUE))
		owner.balloon_alert(owner, "сбито!")
		return
	owner.balloon_alert(owner, "успех!")
	swarmer_proj_mode = new choice
	swarmer_proj_mode.link_mode(owner)
	swarmer_proj_mode.apply_mode()

/datum/action/innate/swarmer/mode_switcher/Remove(mob/user)
	. = ..()
	swarmer_proj_mode = null
