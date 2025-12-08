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

/datum/team/swarmer_team/New(list/starting_members)
	..()
	RegisterSignal(SSdcs, COMSIG_GLOB_SWARMER_CORE_DESTROYED, PROC_REF(on_core_destroy))
	RegisterSignal(src, COMSIG_SWARMER_TRY_PROCESS_ORGANIC_ITEM, PROC_REF(try_process_organic))
	RegisterSignal(src, COMSIG_SWARMER_TRY_ANALYZE_MOB, PROC_REF(try_analyze_mob))
	RegisterSignal(src, COMSIG_SWARMER_STORAGE_INITIALIZED, PROC_REF(increase_modifier))
	RegisterSignal(src, COMSIG_SWARMER_STORAGE_DESTROYED, PROC_REF(decrease_modifier))

/datum/team/swarmer_team/Destroy(force)
	UnregisterSignal(SSdcs, COMSIG_GLOB_SWARMER_CORE_DESTROYED)
	UnregisterSignal(src, COMSIG_SWARMER_TRY_PROCESS_ORGANIC_ITEM)
	UnregisterSignal(src, COMSIG_SWARMER_TRY_ANALYZE_MOB)
	UnregisterSignal(src, COMSIG_SWARMER_STORAGE_INITIALIZED)
	UnregisterSignal(src, COMSIG_SWARMER_STORAGE_DESTROYED)
	return ..()

/**
 * Signal proc sent on swarmer core destroy
 *
 * Sets resource vars to initial values, cleans
 * the core reference.
 */
/datum/team/swarmer_team/proc/on_core_destroy()
	SIGNAL_HANDLER
	swarmer_core = null
	metallic_resources = 0
	organic_resources = 0

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
