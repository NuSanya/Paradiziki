#define BINGLE_EVOLVE "bingle evolve"
/* to add:
if too much trash on ground bingles roll
*/
/datum/antagonist/bingle
	name = "Bingle"
	roundend_category = "bingles"
	job_rank = ROLE_BINGLE
	antag_hud_name = "hudbingle"
	var/static/datum/team/bingles/bingle_team
	var/obj/structure/bingle_hole/pit_check


/datum/antagonist/bingle/on_gain()
	bingle_team = team
	. = ..()

/datum/antagonist/bingle/greet()
	var/list/messages = list()
	messages.Add(span_blue("<center>Вы Бингл!</center>"))
	messages.Add("<center>Кормите яму любой ценой! Яму можно кормить любым предметом, а также людьми.</center>")
	SEND_SOUND(owner.current, sound('sound/misc/sadtrombone.ogg'))
	return messages

/datum/antagonist/bingle/get_team()
	return bingle_team

/datum/action/innate/bingle/spawn_hole
	name = "Spawn Bingle Pit"
	desc = "Призовите яму, которую вы будете заполнять вещами."
	button_icon = 'icons/mob/bingle/binglepit.dmi'
	button_icon_state = "binglepit"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/innate/bingle/spawn_hole/Activate(atom/target)
	if(!isliving(owner))
		return FALSE
	var/turf/selected_turf = get_turf(owner)
	if(!check_hole_spawn(selected_turf))
		to_chat(owner, span_warning("Это место не имеет достаточно места для ямы! Требуется минимум 3 на 3 метра свободного пространства."))
		return FALSE
	spawn_hole(selected_turf)


/datum/action/innate/bingle/spawn_hole/proc/check_hole_spawn(turf/selected_turf)
	for(var/turf/adjacent_turf as anything in RANGE_TURFS(1, selected_turf))
		if(isnull(adjacent_turf) || adjacent_turf.density)
			return FALSE
	return TRUE

/datum/action/innate/bingle/spawn_hole/proc/spawn_hole(turf/selected_turf)
    var/datum/antagonist/bingle/bingle_datum = owner.mind?.has_antag_datum(/datum/antagonist/bingle)
    if(!selected_turf)
        to_chat(owner, span_notice("Не найден выбранный пол!"))
        return
    var/obj/structure/bingle_hole/hole = new(selected_turf)
    bingle_datum.pit_check = hole
    // Register the team in the pit
    hole.bingle_team = bingle_datum.get_team()
    Remove(owner)
