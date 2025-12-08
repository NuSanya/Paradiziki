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
	swarmer_class_info = "Данный класс не отличается ничем особенным, и существует для того, чтобы вы его сменили в ядре на новый.\n\
		Для смены класса, нажмите по ядру в 1 интенте \"Помощь\".\n\
		Достаточно маленький для того, чтобы проползать под столами и шлюзами."

/**
 * Generalist swarmer
 *
 * Combat unit that is basically the "old" swarmer.
 * Increased speed, can build traps and barricades, shoot projectiles.
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
	swarmer_class_info = "Данный класс является базовой боевой единицей, оснащённой пушкой, а также способностью строить баррикады и ловушки.\n\
		Скорость равна человеческой."

/mob/living/simple_animal/hostile/swarmer/generalist/Initialize(mapload)
	. = ..()
	var/datum/action/innate/swarmer/build/barricade/build_barricade = new
	var/datum/action/innate/swarmer/build/trap/build_trap = new
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

/mob/living/simple_animal/hostile/swarmer/rover/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_HOSTILE_POST_ATTACKINGTARGET, PROC_REF(on_attack))
	var/datum/action/innate/swarmer/build/transport_hub/build_hub = new
	var/datum/action/innate/swarmer/build/trap/build_trap = new
	build_hub.Grant(src)
	build_trap.Grant(src)

/// Signal proc, additional knockdown on attack
/mob/living/simple_animal/hostile/swarmer/rover/proc/on_attack(datum/source, mob/living/target, result)
	SIGNAL_HANDLER
	if(!result)
		return
	if(!istype(target))
		return
	target.Knockdown(3 SECONDS)

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

