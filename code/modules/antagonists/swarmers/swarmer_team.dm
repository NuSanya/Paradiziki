/// How many metallic resources swarmers get on core init
#define METALLIC_START_RESOURCES 150

/datum/team/swarmer_team
	name = "Свармеры"
	antag_datum_type = /datum/antagonist/swarmer
	need_antag_hud = FALSE
	/// Reference to our swarmer core.
	var/obj/structure/swarmer/core/swarmer_core
	/// Amount of inorganic resources we currently have
	var/metallic_resources = 0
	/// Amount of organic resources we currently have
	var/organic_resources = 0
	/// Modifier of metal gatherings by swarmers (not structures)
	var/metal_modifier = 1
	/// Cooldown system for messages on core integrity change
	COOLDOWN_DECLARE(message_cooldown)

/datum/team/swarmer_team/New(list/starting_members)
	..()
	RegisterSignal(src, COMSIG_SWARMER_CORE_INITIALIZED, PROC_REF(on_core_init))
	RegisterSignal(SSdcs, COMSIG_GLOB_SWARMER_CORE_DESTROYED, PROC_REF(on_core_destroy))
	RegisterSignal(src, COMSIG_SWARMER_TRY_PROCESS_ORGANIC_ITEM, PROC_REF(try_process_organic))
	RegisterSignal(src, COMSIG_SWARMER_TRY_ANALYZE_MOB, PROC_REF(try_analyze_mob))
	RegisterSignal(src, COMSIG_SWARMER_STORAGE_INITIALIZED, PROC_REF(increase_modifier))
	RegisterSignal(src, COMSIG_SWARMER_STORAGE_DESTROYED, PROC_REF(decrease_modifier))

/datum/team/swarmer_team/Destroy(force)
	if(swarmer_core) // signals registered on core init
		UnregisterSignal(swarmer_core, COMSIG_OBJ_INTEGRITY_CHANGED)
		UnregisterSignal(swarmer_core, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(src, COMSIG_SWARMER_CORE_INITIALIZED)
	UnregisterSignal(SSdcs, COMSIG_GLOB_SWARMER_CORE_DESTROYED)
	UnregisterSignal(src, COMSIG_SWARMER_TRY_PROCESS_ORGANIC_ITEM)
	UnregisterSignal(src, COMSIG_SWARMER_TRY_ANALYZE_MOB)
	UnregisterSignal(src, COMSIG_SWARMER_STORAGE_INITIALIZED)
	UnregisterSignal(src, COMSIG_SWARMER_STORAGE_DESTROYED)
	return ..()

/**
 * Signal proc sent on swarmer core init
 *
 * Sets swarmer_core variable, adjusts required resources,
 * registers required core signals.
 */
/datum/team/swarmer_team/proc/on_core_init(datum/source, obj/core)
	SIGNAL_HANDLER
	swarmer_core = core
	metallic_resources = METALLIC_START_RESOURCES
	RegisterSignal(swarmer_core, COMSIG_OBJ_INTEGRITY_CHANGED, PROC_REF(on_core_integrity_changed))
	RegisterSignal(swarmer_core, COMSIG_MOVABLE_MOVED, PROC_REF(on_core_moved))

/**
 * Signal proc sent on swarmer core destroy
 *
 * Sets resource vars to initial values, cleans
 * the core reference, unregisters some core based signals.
 */
/datum/team/swarmer_team/proc/on_core_destroy(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(swarmer_core, COMSIG_OBJ_INTEGRITY_CHANGED)
	UnregisterSignal(swarmer_core, COMSIG_MOVABLE_MOVED)
	swarmer_core = null
	metallic_resources = 0
	organic_resources = 0

/**
 * Signal proc sent on swarmer core integrity change
 *
 * Sends a huge message in chat to all members on core being damaged with a cooldown.
 */
/datum/team/swarmer_team/proc/on_core_integrity_changed(datum/source, old_value, new_value)
	SIGNAL_HANDLER
	if(new_value >= old_value)
		return
	if(!COOLDOWN_FINISHED(src, message_cooldown))
		return

	COOLDOWN_START(src, message_cooldown, 3 SECONDS)
	var/area/core_area = get_area(swarmer_core)
	var/locname = initial(core_area.name)
	for(var/datum/mind/swarmer_mind in members)
		var/mob/living/target = swarmer_mind?.current
		if(!target)
			continue
		target.balloon_alert(target, "обнаружено повреждение ядра!")
		to_chat(target, span_boldwarning("Внимание: Обнаружено повреждение ядра! Местоположение: [locname]."))
		// nuSanya -> add some sound

/**
 * Signal proc sent on swarmer core being moved
 *
 * Sends a huge message in chat to all members on core being moved.
 */
/datum/team/swarmer_team/proc/on_core_moved(datum/source, atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	SIGNAL_HANDLER
	var/area/core_area = get_area(swarmer_core)
	var/locname = initial(core_area.name)
	for(var/datum/mind/swarmer_mind in members)
		var/mob/living/target = swarmer_mind?.current
		if(!target)
			continue
		target.balloon_alert(target, "обнаружено перемещение ядра!")
		to_chat(target, span_boldwarning("Внимание: Обнаружено перемещение ядра! Новое местоположение: [locname]."))
		// nuSanya -> add some sound

/**
 * Signal proc used in organic processing (not mobs)
 *
 * Sends signals to organic processers one by one, if there are any, until
 * any signal returns TRUE.
 *
 * Returns TRUE, if any sent signal has return TRUE.
 * Returns FALSE otherwise.
 */
/datum/team/swarmer_team/proc/try_process_organic(datum/source, obj/item)
	SIGNAL_HANDLER
	for(var/obj/structure/swarmer/organic_processer/processer in GLOB.swarmer_objects)
		if(SEND_SIGNAL(processer, COMSIG_SWARMER_PROCESS_ORGANIC_ITEM_CHECK, item) & TRUE)
			return TRUE
	return FALSE

/**
 * Signal proc used in organic analyzing (mobs)
 *
 * Sends signals to organic analyzers one by one, if there are any, until
 * any signal returns TRUE.
 *
 * Returns TRUE, if any sent signal has return TRUE.
 * Returns FALSE otherwise.
 */
/datum/team/swarmer_team/proc/try_analyze_mob(datum/source, mob/living/target)
	SIGNAL_HANDLER
	for(var/obj/structure/swarmer/organic_analyzer/analyzer in GLOB.swarmer_objects)
		if(SEND_SIGNAL(analyzer, COMSIG_SWARMER_ANALYZE_MOB_CHECK, target) & TRUE)
			return TRUE
	return FALSE

/**
 * Signal proc from resource storage
 *
 * Increases metal resource modifier by [SWARMER_STORAGE_MODIFIER].
 * Has a limit of [SWARMER_STORAGE_MODIFIER_LIMIT]
 */
/datum/team/swarmer_team/proc/increase_modifier(datum/source)
	SIGNAL_HANDLER
	metal_modifier = min(metal_modifier + SWARMER_STORAGE_MODIFIER, SWARMER_STORAGE_MODIFIER_LIMIT)

/**
 * Signal proc from resource storage
 *
 * Decreases metal resource modifier by [SWARMER_STORAGE_MODIFIER].
 * Has a limit of 1.
 */
/datum/team/swarmer_team/proc/decrease_modifier(datum/source)
	SIGNAL_HANDLER
	metal_modifier = max(metal_modifier - SWARMER_STORAGE_MODIFIER, 1)

/datum/team/swarmer_team/declare_completion()
	return

/**
 * Global proc to adjust metallic swarmer resource.
 *
 * Set use_modifier to TRUE if you want to use the team metal gather modifier.
 * Returns FALSE if amount was negative and the result is smaller than zero.
 * Returns TRUE otherwise.
 */
/proc/adjust_swarmer_metallic_resources(amount, use_modifier = FALSE)
	var/datum/team/swarmer_team/team = GLOB.antagonist_teams[/datum/team/swarmer_team]
	if(!team.swarmer_core) // Core is the storage
		return FALSE
	if(use_modifier) // Resource storage modifiers (used on swarmer metal gathering)
		amount *= team.metal_modifier
	if(team.metallic_resources + amount < 0)
		return FALSE
	team.metallic_resources = max(team.metallic_resources + amount, 0) // extra precaution
	return TRUE

/**
 * Global proc to adjust organic swarmer resource.
 *
 * Returns FALSE if amount was negative and the result is smaller than zero.
 * Returns TRUE otherwise.
 */
/proc/adjust_swarmer_organic_resources(amount)
	var/datum/team/swarmer_team/team = GLOB.antagonist_teams[/datum/team/swarmer_team]
	if(!team.swarmer_core) // Core is the storage
		return FALSE
	if(team.organic_resources + amount < 0)
		return FALSE
	team.organic_resources = max(team.organic_resources + amount, 0) // extra precaution
	return TRUE

#undef METALLIC_START_RESOURCES
