/**
 * Starting swarmer
 *
 * Nothing unique, exists only to provide a "casing", until
 * the player chooses a new class.
 */
/mob/living/simple_animal/hostile/swarmer/basic
	name = "Drone Swarmer"
	desc = "Хрупкий, маленький, слегка быстрый \"Свармер\"."
	icon_state = "swarmer_starter"
	icon_living = "swarmer_starter"
	melee_damage_lower = 20
	melee_damage_upper = 20
	health = 25
	maxHealth = 25
	dismantle_speed = SLOW_SWARMER_DISMANTLE_DELAY
	speed = 0.25
	can_hide = TRUE
	pass_door_while_hidden = TRUE
	pass_flags = PASSTABLE | PASSMOB
	ventcrawler_trait = TRAIT_VENTCRAWLER_ALWAYS
	can_swap_to = FALSE
	swarmer_class_info = "Данный класс не отличается ничем особенным, и существует для того, чтобы вы его сменили в ядре на новый.\n\
		Для смены класса, нажмите по ядру в 1 интенте \"Помощь\".\n\
		Достаточно маленький для того, чтобы проползать под столами и шлюзами."

/**
 * Generalist swarmer
 *
 * Combat unit that is basically the "old" swarmer.
 * Increased speed, can build small turrets, traps, barricades, shoot projectiles.
 */
/mob/living/simple_animal/hostile/swarmer/generalist
	name = "Generalist Swarmer"
	desc = "Базовая боевая единица \"Свармеров\". Оснащён пушкой и базовыми строительными устройствами."
	icon_state = "swarmer_general"
	icon_living = "swarmer_general"
	melee_damage_lower = 25
	melee_damage_upper = 25
	health = 150
	maxHealth = 150
	speed = 0
	ranged = 1
	projectiletype = /obj/projectile/beam/disabler/swarmer/generalist
	ranged_cooldown_time = SWARMER_NORMAL_PROJECTILE_COOLDOWN
	projectilesound = 'sound/weapons/taser2.ogg'
	swap_resource_cost = GENERALIST_SWAP_COST
	swarmer_class_info = "Данный класс является базовой боевой единицей, оснащённой пушкой, а также способностью строить мелкие туррели, баррикады и ловушки.\n\
		Скорость равна человеческой."

/mob/living/simple_animal/hostile/swarmer/generalist/Initialize(mapload)
	. = ..()
	var/datum/action/innate/swarmer/build/rapid_turret/build_rapid_turret = new
	var/datum/action/innate/swarmer/build/barricade/build_barricade = new
	var/datum/action/innate/swarmer/build/trap/build_trap = new
	build_rapid_turret.Grant(src)
	build_barricade.Grant(src)
	build_trap.Grant(src)

/**
 * Rover Swarmer
 *
 * Scout unit, which means low health, very high speed and high melee damage.
 * Can build "hubs", which are used by swarmers for transportation between them.
 */
/mob/living/simple_animal/hostile/swarmer/rover
	name = "Rover Swarmer"
	desc = "Маленький \"Свармер\" на колёсиках вместо ног. Оснащён тараном, способным опрокидывать с ног целей."
	icon_state = "swarmer_rover"
	icon_living = "swarmer_rover"
	melee_damage_lower = 30
	melee_damage_upper = 30
	health = 55
	maxHealth = 55
	speed = -1
	swap_resource_cost = ROVER_SWAP_COST
	can_hide = TRUE
	pass_door_while_hidden = TRUE
	pass_flags = PASSTABLE | PASSMOB
	swarmer_class_info = "Данный класс является разведовательной единицей, оснащённой колёсами вместо ног, а также мощным тараном, способным сбивать целей с ног.\n\
		Способен строить ловушки и \"хабы\", между которыми смогут перемещаться все \"Свармеры\".\n\
		Достаточно маленький для того, чтобы проползать под столами и шлюзами."
	/// For how long do we knockdown on hit
	var/knockdown_time = 3 SECONDS

/mob/living/simple_animal/hostile/swarmer/rover/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_HOSTILE_POST_ATTACKINGTARGET, PROC_REF(on_attack))
	var/datum/action/innate/swarmer/build/transport_hub/build_hub = new
	var/datum/action/innate/swarmer/build/trap/build_trap = new
	build_hub.Grant(src)
	build_trap.Grant(src)

/mob/living/simple_animal/hostile/swarmer/rover/Destroy(force)
	UnregisterSignal(src, COMSIG_HOSTILE_POST_ATTACKINGTARGET)
	return ..()

/// Signal proc, additional knockdown on attack
/mob/living/simple_animal/hostile/swarmer/rover/proc/on_attack(datum/source, mob/living/target, result)
	SIGNAL_HANDLER
	if(!result)
		return
	if(!istype(target))
		return
	target.Knockdown(knockdown_time)

/**
 * Combat Swarmer
 *
 * Auto-repairs nears the core, has increased speed around swarmer structures.
 * Has 4 different projectile modes, and can build barricades.
 */
/mob/living/simple_animal/hostile/swarmer/combat
	name = "Combat Swarmer"
	desc = "Защитная единица \"Свармеров\". Оснащён пушкой и базовыми строительными устройствами."
	icon_state = "swarmer_combat"
	icon_living = "swarmer_combat"
	melee_damage_lower = 30
	melee_damage_upper = 30
	health = 220
	maxHealth = 220
	dismantle_speed = SLOW_SWARMER_DISMANTLE_DELAY
	speed = 1.5
	ranged = 1
	swap_resource_cost = COMBAT_SWAP_COST
	swarmer_class_info = "Данный класс является защитной единицей, оснащённой более сильной защитой и пушками.\n\
		Оснащён следующими типами выстрелов: Обычный выстрел, двойной выстрел, сильный выстрел, саботажный выстрел.\n\
		Способен строить баррикады.\n\
		Чинится автоматически у ядра, становится быстрее у ядра."
	/// Our current projectile mode datum, used in mode_switcher action and on init
	var/datum/swarmer_proj_mode/swarmer_proj_mode

/mob/living/simple_animal/hostile/swarmer/combat/Initialize(mapload)
	. = ..()
	swarmer_proj_mode = new /datum/swarmer_proj_mode/general // set to default mode on init
	swarmer_proj_mode.link_mode(src)
	swarmer_proj_mode.apply_mode()

	START_PROCESSING(SSprocessing, src)
	ADD_TRAIT(src, TRAIT_HEALS_FROM_SWARMER_CORES, INNATE_TRAIT)

	var/datum/action/innate/swarmer/mode_switcher/mode_switcher = new
	var/datum/action/innate/swarmer/build/barricade/build_barricade = new
	build_barricade.Grant(src)
	mode_switcher.Grant(src)

/mob/living/simple_animal/hostile/swarmer/combat/Destroy()
	QDEL_NULL(swarmer_proj_mode)
	STOP_PROCESSING(SSprocessing, src)
	REMOVE_TRAIT(src, TRAIT_HEALS_FROM_SWARMER_CORES, INNATE_TRAIT)
	return ..()

/// Increases speed if any swarmer structure is nearby
/mob/living/simple_animal/hostile/swarmer/combat/process(seconds_per_tick)
	for(var/obj/structure/swarmer/swarmer_str in view(src)) // If we have any swarmer structure nearby, increase the speed
		set_varspeed(0)
		return
	set_varspeed(initial(speed))

/**
 * Builder Swarmer
 *
 * The most important class of all. Builds most of swarmer structures,
 * can move them, and repairs twice more and twice faster.
 */
/mob/living/simple_animal/hostile/swarmer/builder
	name = "Builder Swarmer"
	desc = "Строительная единица \"Свармеров\". Оснащён мощными нанитами, способными как строить, так и чинить, за крайне малое время."
	icon_state = "swarmer_builder"
	icon_living = "swarmer_builder"
	melee_damage_lower = 40
	melee_damage_upper = 40
	health = 120
	maxHealth = 120
	dismantle_speed = FAST_SWARMER_DISMANTLE_DELAY
	swap_resource_cost = BUILDER_SWAP_COST
	mob_size = MOB_SIZE_HUMAN
	swarmer_class_info = "Данный класс является строительной единицей, способной строить множество различных конструкций.\n\
		Является самым важным классом среди \"Свармеров\", без которого выполнение цели является невозможным.\n\
		Чинит в два раза быстрее и больше остальных, а также способен перемещать структуры, включая ядро.\n\
		Медленно чинится сам по себе, и обладает наибольшим уроном вблизи."
	/// Builder swarmers heal passively by a little bit
	var/auto_repair_amount = 1

// To be fair this is a bit too much, but whatever
/mob/living/simple_animal/hostile/swarmer/builder/Initialize(mapload)
	. = ..()
	var/datum/action/innate/swarmer/build/processer/build_processer = new
	var/datum/action/innate/swarmer/build/analyzer/build_analyzer = new
	var/datum/action/innate/swarmer/build/repair_station/build_repair_station = new
	var/datum/action/innate/swarmer/build/storage/build_storage = new
	var/datum/action/innate/swarmer/build/rapid_turret/build_rapid_turret = new
	var/datum/action/innate/swarmer/build/sniper_turret/build_sniper_turret = new
	var/datum/action/innate/swarmer/build/acp_turret/build_acp = new
	build_processer.Grant(src)
	build_analyzer.Grant(src)
	build_repair_station.Grant(src)
	build_storage.Grant(src)
	build_rapid_turret.Grant(src)
	build_sniper_turret.Grant(src)
	build_acp.Grant(src)

/mob/living/simple_animal/hostile/swarmer/builder/Life(seconds, times_fired)
	. = ..()
	adjustHealth(-auto_repair_amount)

/**
 * Finishing goal of swarmers.
 *
 * Tanky, reflects projectiles, has a built-in
 * minigun and ACP.
 * nuSanya -> this should have minigun recharge mechanics, later
 */
/mob/living/simple_animal/hostile/swarmer/mega
	name = "Mega Swarmer"
	desc = "Лучшая боевая единица \"Свармеров\", оснащённая рефлекторными пластинами, миниганом, и встроенной турелью ACP."
	icon_state = "swarmer_mega"
	icon_living = "swarmer_mega"
	melee_damage_lower = 60
	melee_damage_upper = 60
	ranged = 1
	projectiletype = /obj/projectile/beam/disabler/swarmer/minigun
	ranged_cooldown_time = SWARMER_MINIGUN_PROJECTILE_COOLDOWN
	projectilesound = 'sound/weapons/taser2.ogg'
	rapid = SWARMER_MEGA_RAPID
	rapid_fire_delay = 1
	health = 650
	maxHealth = 650
	can_swap_to = FALSE
	move_force = MOVE_FORCE_OVERPOWERING
	move_resist = MOVE_FORCE_OVERPOWERING
	pull_force = MOVE_FORCE_OVERPOWERING
	dismantle_speed = FAST_SWARMER_DISMANTLE_DELAY
	swarmer_class_info = "Вы - финальная боевая единица \"Свармеров\", оснащённая миниганом, встроенной ACP турелью, а также защитными пластинами.\n\
		Ваша цель - окончательно захватить станцию под ваш контроль."
	/// For how long we apply knockdown on attack
	var/knockdown_time = 5 SECONDS
	/// Reflection chance of projectiles
	var/reflection_chance = SWARMER_MEGA_REFLECT_CHANCE
	/// Built-in ACP turret
	var/obj/structure/swarmer/acp_turret/acp
	/// Built-in ACP turret range
	var/acp_range = SWARMER_MEGA_ACP_RANGE

/mob/living/simple_animal/hostile/swarmer/mega/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_HOSTILE_POST_ATTACKINGTARGET, PROC_REF(on_attack))
	acp = new(src)
	configure_acp()

/mob/living/simple_animal/hostile/swarmer/mega/Destroy(force)
	UnregisterSignal(src, COMSIG_HOSTILE_POST_ATTACKINGTARGET)
	qdel(acp)
	return ..()

/// Signal proc, additional knockdown on attack
/mob/living/simple_animal/hostile/swarmer/mega/proc/on_attack(datum/source, mob/living/target, result)
	SIGNAL_HANDLER
	if(!result)
		return
	if(!istype(target))
		return
	target.Knockdown(knockdown_time)

/// Reflects projectiles with a set chance
/mob/living/simple_animal/hostile/swarmer/mega/bullet_act(obj/projectile/proj)
	if(!proj.is_reflectable(REFLECTABILITY_ENERGY))
		return ..()
	if(!prob(reflection_chance))
		return ..()

	if(proj.damage_type == BRUTE || proj.damage_type == BURN)
		adjustHealth(proj.damage * 0.5)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] отражает [proj.declent_ru(ACCUSATIVE)]!"), \
			span_userdanger("[capitalize(declent_ru(NOMINATIVE))] отражает [proj.declent_ru(ACCUSATIVE)]!"),\
			projectile_message = TRUE)
	add_attack_logs(proj.firer, src, "hit by [proj.type] but got reflected")
	proj.reflect_back(src)
	return -1

/// Configures ACP to work within src
/mob/living/simple_animal/hostile/swarmer/mega/proc/configure_acp()
	QDEL_NULL(acp.proximity_monitor)
	acp.proximity_monitor = new(src, acp_range)
	acp.range = acp_range

/// Connects proximity monitor of us with acp's
/mob/living/simple_animal/hostile/swarmer/mega/HasProximity(atom/movable/AM)
	acp.handle_interloper(AM)

/// Makes this swarmer one-shot most allowed things.
/mob/living/simple_animal/hostile/swarmer/mega/disintegrate(atom/movable/target)
	. = ..()
	target.ex_act(EXPLODE_DEVASTATE)
