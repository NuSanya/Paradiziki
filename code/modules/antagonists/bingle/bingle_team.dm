/datum/team/bingles
	name = "Бинглы"
	antag_datum_type = /datum/antagonist/bingle
	need_antag_hud = FALSE
	/// List of all bingle holes ingame. Added and removed privately.
	var/list/bingle_holes = list()
	/// Main bingle objective. Given to all bingles.
	var/datum/objective/bingle/main_objective

/datum/team/bingles/New(list/starting_members)
	..()
	RegisterSignal(src, COMSIG_BINGLE_HOLE_INITIALIZED, PROC_REF(on_hole_init))
	RegisterSignal(src, COMSIG_MASS_BINGLE_EVOLVE, PROC_REF(on_hole_evolve))
	main_objective = new(team_to_join = src)
	add_objective_to_members(main_objective)

/datum/team/bingles/Destroy(force)
	UnregisterSignal(src, COMSIG_BINGLE_HOLE_INITIALIZED)
	UnregisterSignal(src, COMSIG_MASS_BINGLE_EVOLVE)
	for(var/obj/structure/bingle_hole/hole as anything in bingle_holes)
		UnregisterSignal(hole, COMSIG_QDELETING)
	QDEL_NULL(main_objective)
	bingle_holes = null
	return ..()

/datum/team/bingles/declare_completion()
	var/list/text = list()
	if(main_objective.completed)
		text += span_fontsize3("<br><br><b>Победа \"Бинглов\"!</b>")
		text += "<br><b>Бинглы смогли вырастить яму до такого размера, что она поглотила станцию!</b>"
	else
		text += span_fontsize3("<br><br><b>Поражение \"Бинглов\"!</b>")
		text += "<br><b>Бинглы не смогли поглотить станцию целиком, так как экипаж сумел их остановить.</b>"
	return text.Join("")

/// Signal proc called on hole initialization
/datum/team/bingles/proc/on_hole_init(datum/source, obj/structure/bingle_hole/hole)
	SIGNAL_HANDLER
	bingle_holes += hole
	RegisterSignal(hole, COMSIG_QDELETING, PROC_REF(on_hole_destroy))

/**
 * Signal proc called on hole destroy
 *
 * Kills all bingles related to that hole (except for bingle lords),
 * Unregisters some signals
 */
/datum/team/bingles/proc/on_hole_destroy(obj/structure/bingle_hole/source)
	SIGNAL_HANDLER
	bingle_holes -= source
	UnregisterSignal(source, COMSIG_QDELETING)
	// Shouldn't be laggy, so far as tested
	if(!LAZYACCESS(GLOB.bingles_by_hole, source.UID()))
		return
	for(var/mob/living/simple_animal/hostile/bingle/bingle as anything in GLOB.bingles_by_hole[source.UID()])
		bingle?.gib()

/// Signal proc that sends evolve signal to all bingles related to the hole
/datum/team/bingles/proc/on_hole_evolve(datum/source, obj/structure/bingle_hole/hole)
	SIGNAL_HANDLER
	if(!LAZYACCESS(GLOB.bingles_by_hole, hole.UID()))
		return
	for(var/mob/living/simple_animal/hostile/bingle/bingle as anything in GLOB.bingles_by_hole[hole.UID()])
		if(!bingle || bingle.evolved)
			continue
		SEND_SIGNAL(bingle, COMSIG_BINGLE_EVOLVE)
