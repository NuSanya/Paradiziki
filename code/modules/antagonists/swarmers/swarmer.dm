/// List that contains all swarmers mobs.
GLOBAL_LIST_EMPTY(swarmers)

/mob/living/simple_animal/hostile/swarmer
	name = "Swarmer"
	real_name = "Swarmer"
	desc = "Напишите баг-репорт, если увидили это."
	health = 35
	maxHealth = 35
	icon = 'icons/mob/swarmer.dmi'
	icon_state = "swarmer_old"
	icon_living = "swarmer_old"
	speak_emote = list("гудит")
	bubble_icon = "swarmer"
	mob_size = MOB_SIZE_SMALL
	melee_damage_type = STAMINA
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	hud_possible = list(SPECIALROLE_HUD, DIAG_STAT_HUD, DIAG_HUD)
	obj_damage = 0
	friendly = "щипает"
	faction = list(ROLE_SWARMER)
	AIStatus = AI_OFF
	wander = 0
	attacktext = "бьёт током"
	attack_sound = 'sound/effects/empulse.ogg'
	deathmessage = "взрывается с резким хлопком!"
	del_on_death = 1
	loot = list(/obj/effect/decal/cleanable/robot_debris, /obj/item/stack/ore/bluespace_crystal)
	light_system = MOVABLE_LIGHT
	light_color = LIGHT_COLOR_CYAN
	light_range = 3
	light_on = FALSE
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	hud_type = /datum/hud/swarmer
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 0
	move_force = MOVE_FORCE_DEFAULT
	pull_force = PULL_FORCE_DEFAULT
	/// Text used in core tgui and sent to client to tell about current class abilities
	var/swarmer_class_info = "Напишите баг-репорт, если увидили это."
	/// How much time does it take to dismantle a machine
	var/dismantle_speed = NORMAL_SWARMER_DISMANTLE_DELAY
	/// How many resources does it require to swap to this class from an existing one
	var/swap_resource_cost = 0
	/// Can swarmers swap to this type in core?
	var/can_swap_to = TRUE
	/// Reference to swarmer team
	var/datum/team/swarmer_team/team
	/// Spark system (since we use them a lot)
	var/datum/effect_system/spark_spread/spark_system
	/// Mmi inside contents if this swarmer is from a cyborg
	var/obj/item/mmi/mmi

/mob/living/simple_animal/hostile/swarmer/Initialize(mapload)
	. = ..()
	GLOB.swarmers += src
	spark_system = new
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)
	add_language(LANGUAGE_HIVE_SWARMER)
	updatename()
	RegisterSignal(src, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.huds)
		diag_hud.add_atom_to_hud(src)
	// Grants all required on-init actions to this type
	for(var/action_type in GLOB.swarmer_actions_by_type[type])
		var/datum/action/cooldown/swarmer/action = new action_type
		action.Grant(src)

/mob/living/simple_animal/hostile/swarmer/ComponentInitialize()
	AddComponent( \
		/datum/component/animal_temperature, \
		maxbodytemp = INFINITY, \
		minbodytemp = 0, \
	)
	AddComponent(\
		/datum/component/ghost_direct_control, \
		ban_type = ROLE_SWARMER, \
		poll_candidates = FALSE, \
		after_assumed_control = CALLBACK(src, PROC_REF(add_datum_if_not_exist)), \
	)

/// Just some sparks on death.
/mob/living/simple_animal/hostile/swarmer/death(gibbed)
	spark_system.start()
	return ..()

/mob/living/simple_animal/hostile/swarmer/Destroy()
	GLOB.swarmers -= src
	QDEL_NULL(spark_system)
	UnregisterSignal(src, COMSIG_LIVING_UNARMED_ATTACK)
	team = null
	handle_mmi_on_destroy()
	return ..()

/mob/living/simple_animal/hostile/swarmer/proc/updatename()
	real_name = "[name] [rand(100,999)]-[pick("kappa","sigma","beta","omicron","iota","epsilon","omega","gamma","delta","tau","alpha")]"
	name = real_name

/mob/living/simple_animal/hostile/swarmer/get_status_tab_items()
	var/list/status_tab_data = ..()
	. = status_tab_data
	status_tab_data[++status_tab_data.len] = list("Металлические ресурсы: ", team.metallic_resources)
	status_tab_data[++status_tab_data.len] = list("Органические ресурсы: ", team.organic_resources)
	if(team.swarmer_core)
		status_tab_data[++status_tab_data.len] = list("Здоровье ядра: ", "[team.swarmer_core.obj_integrity]/[team.swarmer_core.max_integrity]")

/// Swarmers get damaged on emp
/mob/living/simple_animal/hostile/swarmer/emp_act()
	..()
	adjustHealth(SWARMER_EMP_DAMAGE, forced = TRUE)

/// Swarmer projectiles pass through swarmers
/mob/living/simple_animal/hostile/swarmer/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(is_swarmerprojectile(mover))
		return TRUE

/// Handles dealing actual damage to cyborgs and animals.
/mob/living/simple_animal/hostile/swarmer/AttackingTarget()
	. = ..()
	if(isswarmer(target))
		return .
	if(issilicon(target) || isanimal(target))
		var/mob/living/difficult_target = target
		var/damage = rand(melee_damage_lower, melee_damage_upper)
		difficult_target.apply_damage(damage, BURN)

/**
 * This proc handles sending mobs to analyzers and converting cyborgs.
 */
/mob/living/simple_animal/hostile/swarmer/CtrlClickOn(atom/A)
	if(A == src)
		return ..()
	if(!isliving(A) || isswarmer(A))
		return ..()
	if(!A.Adjacent(src))
		return ..()
	if(!issilicon(A)) // Non-silicon mobs
		return try_disperse(A)
	if(isrobot(A)) // Cyborgs
		return try_convert(A)

/// The only interaction by swarmers with other swarmers is repairing them.
/mob/living/simple_animal/hostile/swarmer/swarmer_act(mob/living/simple_animal/hostile/swarmer/other_swarmer)
	if(src == other_swarmer)
		balloon_alert(src, "нельзя чинить себя!")
		return
	balloon_alert(other_swarmer, "вас чинят!")
	other_swarmer.balloon_alert(other_swarmer, "починка!")
	if(!do_after(other_swarmer, SWARMER_REPAIR_DELAY(other_swarmer), src, max_interact_count = 1))
		return
	if(!adjust_swarmer_metallic_resources(-SWARMER_REPAIR_COST))
		other_swarmer.balloon_alert(other_swarmer, "недостаточно ресурсов!")
		return
	adjustHealth(-SWARMER_REPAIR_AMOUNT(other_swarmer))

/**
 * Unarmed_Attack signal proc
 *
 * Used to handle the following:
 * Swarmer acts on non-living beings
 * Sending organic stuff to the organic processer
 * Repairing other swarmers
 */
/mob/living/simple_animal/hostile/swarmer/proc/on_unarmed_attack(datum/source, atom/atom, proximity_flag)
	SIGNAL_HANDLER
	if(isliving(atom) && !isswarmer(atom)) // Living mobs (except swarmers) are handled normally
		return
	if(handle_organic_sending(atom))
		return COMPONENT_CANCEL_ATTACK_CHAIN
	INVOKE_ASYNC(atom, TYPE_PROC_REF(/atom, swarmer_act), src)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/// Handles sending various stuff into organic processor.
/mob/living/simple_animal/hostile/swarmer/proc/handle_organic_sending(atom/atom)
	. = TRUE
	if(is_grownsnacks(atom) || isgrown(atom) || is_seeds(atom))
		INVOKE_ASYNC(src, PROC_REF(send_organic_processer_signal), atom, SWARMER_SEND_ORGANIC_DELAY)
		return .
	if(is_hydroponics(atom))
		INVOKE_ASYNC(src, PROC_REF(handle_hydroponics_processing), atom) // Separate, because we clean the tray first.
		return .
	if(is_reagentcontainer(atom))
		INVOKE_ASYNC(src, PROC_REF(handle_container_processing), atom) // Separate, because we check for reagents first.
		return .
	return FALSE

/**
 * Hydroponics processing handling.
 *
 * Empties the tray after do_after and then sends a signal.
 */
/mob/living/simple_animal/hostile/swarmer/proc/handle_hydroponics_processing(obj/machinery/hydroponics/hydroponics)
	if(!hydroponics.myseed) // If there is no plant, then there is nothing to process
		hydroponics.swarmer_act(src)
		return
	if(!do_after(src, SWARMER_SEND_ORGANIC_DELAY, hydroponics, max_interact_count = 1))
		balloon_alert(src, "сбито!")
		return

	// Clean the hydroponic lot
	hydroponics.age = 0
	hydroponics.plant_health = 0
	if(hydroponics.harvest)
		hydroponics.harvest = FALSE //To make sure they can't just put in another seed and insta-harvest it
	qdel(hydroponics.myseed)
	hydroponics.myseed = null
	hydroponics.plant_hud_set_health()
	hydroponics.plant_hud_set_status()
	hydroponics.update_state()

	send_organic_processer_signal() // Arguments being null is intentional, we aren't sending anything and not delaying

/**
 * Reagent container processing
 *
 * Checks if we have any reagent, and if we do,
 * then we send. Otherwise, we don't.
 * TODO: make it work only for organic chems?
 */
/mob/living/simple_animal/hostile/swarmer/proc/handle_container_processing(obj/item/reagent_containers/container)
	if(!container.reagents?.total_volume) // Checks if there is any reagent in the container
		container.swarmer_act(src)
		return
	send_organic_processer_signal(container, SWARMER_SEND_ORGANIC_DELAY)

/**
 * Proc for organic processing.
 *
 * Handles do_after and sends COMSIG_SWARMER_TRY_PROCESS_ORGANIC_ITEM signal to the team.
 */
/mob/living/simple_animal/hostile/swarmer/proc/send_organic_processer_signal(obj/item, delay)
	balloon_alert(src, "отправка...")
	var/atom/delay_target = item ? item : src // The item can be null intentionally
	if(delay && !do_after(src, delay, delay_target, max_interact_count = 1))
		balloon_alert(src, "сбито!")
		return
	if(SEND_SIGNAL(team, COMSIG_SWARMER_TRY_PROCESS_ORGANIC_ITEM, item) & TRUE)
		balloon_alert(src, "успешно отправлено!")
		spark_system.start()
		return
	balloon_alert(src, "нету места для органики!")

/**
 * Proc used to disperse of mobs.
 *
 * Handles do_after and sends COMSIG_SWARMER_TRY_ANALYZE_MOB signal to the team.
 * If signal returns FALSE, we teleport the target randomly.
 * Used in CtrlClick proc.
 */
/mob/living/simple_animal/hostile/swarmer/proc/try_disperse(mob/living/target)
	balloon_alert(src, "отправка...")
	if(!do_after(src, SWARMER_SEND_ORGANIC_DELAY, target, max_interact_count = 1))
		balloon_alert(src, "сбито!")
		return
	spark_system.start()
	if(SEND_SIGNAL(team, COMSIG_SWARMER_TRY_ANALYZE_MOB, target) & TRUE)
		balloon_alert(src, "отправлено в анализатор!")
		return
	if(!iscarbon(target))
		balloon_alert(src, "нету места для органики!")
		return
	fail_disperse_teleport(target)

/**
 * Proc called if no free organic analyzers were found
 *
 * Puts restrains on target, adjust organic resources slightly
 * and teleports them randomly.
 */
/mob/living/simple_animal/hostile/swarmer/proc/fail_disperse_teleport(mob/living/carbon/target)
	var/turf/safe_turf = find_safe_turf(z)
	if(!safe_turf)
		balloon_alert(src, "нет мест для телепорта!")
		return
	if(!target.handcuffed)
		target.apply_restraints(new /obj/item/restraints/handcuffs/energy/used(null), ITEM_SLOT_HANDCUFFED, TRUE)
	target.Sleeping(10 SECONDS)
	balloon_alert(src, "случайно телепортировано!")
	playsound(src, 'sound/effects/sparks4.ogg', 50, TRUE)
	adjust_swarmer_organic_resources(SWARMER_ANALYZE_TELEPORT_GAIN)
	do_teleport(target, safe_turf)

/// Proc used to convert cyborgs to swarmers.
/mob/living/simple_animal/hostile/swarmer/proc/try_convert(mob/living/silicon/robot/target)
	if(!target.mind)
		balloon_alert(src, "не имеет разума!")
		return
	balloon_alert(src, "пересобираем...")
	if(!do_after(src, 15 SECONDS, target, max_interact_count = 1))
		balloon_alert(src, "сбито!")
		return
	var/mob/living/simple_animal/hostile/swarmer/combat/new_swarmer = new(get_turf(target))
	if(target.mmi)
		new_swarmer.mmi = target.mmi // Save a reference to mmi in src
		target.mmi.forceMove(new_swarmer) // Forcemove mmi into new swarmer
		target.mmi = null // Clean the reference to mmi in robot
	target.mind.transfer_to(new_swarmer)
	balloon_alert(src, "успех!")
	new_swarmer.spark_system.start()
	add_conversion_logs(target, "Converted into [new_swarmer.name].")
	qdel(target)

/// Proc used on destroy if we have a mmi inside
/mob/living/simple_animal/hostile/swarmer/proc/handle_mmi_on_destroy()
	if(!mmi || !mind)
		return
	mind.transfer_to(mmi.brainmob)
	mmi.forceMove(get_turf(src))
	addtimer(CALLBACK(mmi.brainmob, TYPE_PROC_REF(/mob, offer_ghostize)), 10 SECONDS, TIMER_DELETE_ME)
	mmi = null

/// Proc called in swarmer_act to adjust resources and destroy target
/mob/living/simple_animal/hostile/swarmer/proc/Integrate(atom/movable/target)
	var/resource_gain = target.integrate_amount()
	if(!resource_gain)
		balloon_alert(src, "не совместимо!")
		to_chat(src, span_warning("[target] не является совместимым с нашим переработчиком материалов."))
		return FALSE
	. = TRUE
	adjust_swarmer_metallic_resources(resource_gain, TRUE)
	do_attack_animation(target)
	changeNext_move(CLICK_CD_MELEE)
	var/obj/effect/temp_visual/swarmer/integrate/integrate_effect = new(get_turf(target))
	integrate_effect.adjust_size(target)
	if(!isstack(target))
		qdel(target)
		return .
	var/obj/item/stack/stack_item = target
	stack_item.use(1)

/// Proc called in swarmer_act to damage target.
/mob/living/simple_animal/hostile/swarmer/proc/disintegrate(atom/movable/target)
	var/obj/effect/temp_visual/swarmer/disintegration/disintegrate_effect = new(get_turf(target))
	disintegrate_effect.adjust_size(target)
	target.ex_act(EXPLODE_LIGHT) // This is what actually damages structures on swarmer_act
	do_attack_animation(target)
	changeNext_move(CLICK_CD_MELEE)

/mob/living/simple_animal/hostile/swarmer/electrocute_act(shock_damage, atom/source, siemens_coeff = 1, flags = NONE, jitter_time = 10 SECONDS, stutter_time = 6 SECONDS, stun_duration = 4 SECONDS)
	if(!(flags & SHOCK_TESLA))
		return FALSE
	return ..()

/// Proc called in swarmer_act to dismantle machinery.
/mob/living/simple_animal/hostile/swarmer/proc/dismantle_machine(obj/machinery/target)
	do_attack_animation(target)
	balloon_alert(src, "разбор...")
	var/obj/effect/temp_visual/swarmer/dismantle/dismantle_effect = new(get_turf(target))
	dismantle_effect.adjust_size(target)
	if(!do_after(src, dismantle_speed, target, max_interact_count = 1))
		return
	balloon_alert(src, "успех!")
	target.deconstruct(TRUE)

/mob/living/simple_animal/hostile/swarmer/proc/add_datum_if_not_exist()
	if(mind && !mind.has_antag_datum(/datum/antagonist/swarmer))
		mind.add_antag_datum(/datum/antagonist/swarmer, /datum/team/swarmer_team)
	team = GLOB.antagonist_teams[/datum/team/swarmer_team]

/// mob/living is hardcoded to have medhud. So we change medhud to appear as diaghud
/mob/living/simple_animal/hostile/swarmer/med_hud_set_health()
	var/image/holder = hud_list[DIAG_HUD]
	holder.pixel_y = get_cached_height() - ICON_SIZE_Y
	holder.icon_state = "huddiag[RoundDiagBar(health / maxHealth)]"

/// mob/living is hardcoded to have medhud. So we change medhud to appear as diaghud
/mob/living/simple_animal/hostile/swarmer/med_hud_set_status()
	var/image/holder = hud_list[DIAG_STAT_HUD]
	holder.pixel_y = get_cached_height() - ICON_SIZE_Y
	holder.icon_state = "hudstat"

/// Proc used to toggle light on hud
/mob/living/simple_animal/hostile/swarmer/proc/toggle_light()
	if(!light_on && is_ventcrawling(src))
		to_chat(src, span_warning("Нельзя переключить свет в вентиляции!"))
		return
	set_light_on(!light_on)

/// Proc used to communicate with other swarmers
/mob/living/simple_animal/hostile/swarmer/proc/contact_swarmers()
	var/message = tgui_input_text(src, "Передайте сообщение другим \"Свармерам\"", "Канал \"Свармеров\"")
	if(!message)
		return
	message = span_swarmeritalic("<b>[name]:</b> [message]")
	for(var/mob/mob in GLOB.player_list)
		if(isswarmer(mob))
			to_chat(mob, message)
			continue
		if((mob in GLOB.dead_mob_list) && !isnewplayer(mob))
			to_chat(mob, span_swarmeritalic("<a href='byond://?src=[mob.UID()];follow=[UID()]'>(F)</a> [message]"))
	add_say_logs(src, message, language = "SWARMER")

/mob/living/simple_animal/hostile/swarmer/get_ru_names()
	return list(
		NOMINATIVE = "свармер",
		GENITIVE = "свармера",
		DATIVE = "свармеру",
		ACCUSATIVE = "свармера",
		INSTRUMENTAL = "свармером",
		PREPOSITIONAL = "свармере"
	)

/// How many metallic resources swarmers get on integrating this atom
/atom/movable/proc/integrate_amount()
	return 0

/obj/item/integrate_amount()
	if(!length(materials))
		return 0
	if(materials[MAT_METAL] || materials[MAT_GLASS])
		return 1
	return ..()


/obj/effect/temp_visual/swarmer
	icon = 'icons/effects/swarmer.dmi'
	layer = BELOW_MOB_LAYER

/// Use this proc to adjust size according to target.
/obj/effect/temp_visual/swarmer/proc/adjust_size(atom/target)
	pixel_x = target.pixel_x
	pixel_y = target.pixel_y
	pixel_z = target.pixel_z

/obj/effect/temp_visual/swarmer/Initialize(mapload)
	. = ..()
	playsound(loc, SFX_SPARKS, 100, TRUE)

/obj/effect/temp_visual/swarmer/disintegration
	icon_state = "disintegrate"

/obj/effect/temp_visual/swarmer/dismantle
	icon_state = "dismantle"
	duration = 25

/obj/effect/temp_visual/swarmer/integrate
	icon_state = "integrate"
	duration = 5

// Disabled swarmer shell
/obj/item/deactivated_swarmer
	name = "unactivated swarmer"
	desc = "Деактивированная оболочка свармера. Может оказаться полезным для изучения."
	icon = 'icons/mob/swarmer.dmi'
	icon_state = "swarmer_unactivated"
	origin_tech = "bluespace=4;materials=4;programming=7"
	materials = list(MAT_METAL=10000, MAT_GLASS=4000)

/obj/item/deactivated_swarmer/get_ru_names()
	return list(
		NOMINATIVE = "деактивированная оболочка свармера",
		GENITIVE = "деактивированной оболочки свармера",
		DATIVE = "деактивированной оболочке свармера",
		ACCUSATIVE = "деактивированную оболочку свармера",
		INSTRUMENTAL = "деактивированной оболочкой свармера",
		PREPOSITIONAL = "деактивированной оболочке свармера"
	)

// Used in cases where no-one wanted to play as swarmer
/obj/effect/mob_spawn/swarmer
	name = "unactivated swarmer"
	desc = "Неактивированная оболочка свармера, которая может активироваться в любой момент. Кажется, её можно отключить отвёрткой."
	icon = 'icons/mob/swarmer.dmi'
	icon_state = "swarmer_unactivated"
	density = FALSE
	layer = ABOVE_ALL_MOB_LAYER
	anchored = FALSE
	mob_type = /mob/living/simple_animal/hostile/swarmer/basic
	death = FALSE
	roundstart = FALSE
	allow_tts_pick = FALSE
	banType = ROLE_SWARMER

/obj/effect/mob_spawn/swarmer/Initialize(mapload)
	. = ..()
	// I want these to get destroyed immediately
	RegisterSignal(SSdcs, COMSIG_GLOB_SWARMER_CORE_DESTROYED, PROC_REF(on_core_destroy))
	var/area/A = get_area(src)
	if(A)
		notify_ghosts("Оболочка свамера была создана в [A.name].", 'sound/effects/bin_close.ogg', source = src, action = NOTIFY_ATTACK, flashwindow = FALSE)

/obj/effect/mob_spawn/swarmer/Destroy(force)
	UnregisterSignal(SSdcs, COMSIG_GLOB_SWARMER_CORE_DESTROYED)
	return ..()

/obj/effect/mob_spawn/swarmer/proc/on_core_destroy()
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/mob_spawn/swarmer/screwdriver_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, 3 SECONDS, volume = I.tool_volume))
		return
	user.balloon_alert(user, "деактивировано!")
	new /obj/item/deactivated_swarmer(get_turf(src))
	qdel(src)

/// Flavour var override
/obj/effect/mob_spawn/swarmer/create(mob/plr, flavour = FALSE, name, prefs = FALSE, _mob_name = FALSE, _mob_gender = FALSE, _mob_species = FALSE)
	return ..()

/obj/effect/mob_spawn/swarmer/get_ru_names()
	return list(
		NOMINATIVE = "оболочка свармера",
		GENITIVE = "оболочки свармера",
		DATIVE = "оболочке свармера",
		ACCUSATIVE = "оболочку свармера",
		INSTRUMENTAL = "оболочкой свармера",
		PREPOSITIONAL = "оболочке свармера"
	)
