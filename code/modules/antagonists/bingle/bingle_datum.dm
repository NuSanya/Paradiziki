/* to add:
if too much trash on ground bingles roll
*/
/datum/antagonist/bingle
	name = "Bingle"
	roundend_category = "bingles"
	job_rank = ROLE_BINGLE
	antag_hud_name = "hudbingle"
	show_in_orbit = FALSE
	var/static/datum/team/bingles/bingle_team

/datum/antagonist/bingle/on_gain()
	if(!bingle_team)
		bingle_team = new
		team = bingle_team

	bingle_team.add_member(owner)
	return ..()

/datum/antagonist/bingle/greet()
	var/list/messages = list()
	messages.Add(span_danger("<center>Вы — Бингл!</center>"))
	messages.Add("<center>Работайте сообща, помогайте своим братьям, разбирайте станцию, тащите экипаж в яму, сделайте из этой станции одну большую дыру!</center>")
	SEND_SOUND(owner.current, sound('sound/ambience/antag/bingle.ogg'))
	return messages

/datum/antagonist/bingle/give_objectives()
	if(!bingle_team.pit_check)
		add_objective(/datum/objective/bingle_lord)
	else
		var/datum/objective/bingle/bingle_obj = add_objective(/datum/objective/bingle)
		bingle_obj.pit_check = bingle_team.pit_check

/datum/antagonist/bingle/get_team()
	return bingle_team

/obj/effect/proc_holder/spell/bingle
	name = "Bingle"
	desc = "Напишите баг-репорт, если вы это увидели."
	action_icon = 'icons/mob/bingle/binglepit.dmi'
	clothes_req = FALSE
	human_req = FALSE

/obj/effect/proc_holder/spell/bingle/spawn_hole
	name = "Spawn Bingle Pit"
	desc = "Создаёт яму. Одноразовое."
	action_icon_state = "binglepit"
	create_attack_logs = FALSE
	create_custom_logs = TRUE
	base_cooldown = 20 SECONDS

/obj/effect/proc_holder/spell/bingle/spawn_hole/write_custom_logs(list/targets, mob/user)
	user.create_log(MISC_LOG, "Summoned bingle pit with spell [name]")

/obj/effect/proc_holder/spell/bingle/spawn_hole/create_new_targeting()
	var/datum/spell_targeting/aoe/turf/T = new()
	T.range = 1
	return T

/obj/effect/proc_holder/spell/bingle/spawn_hole/can_cast(mob/user = usr, charge_check = TRUE, show_message = FALSE)
	. = ..()

	if(!isbingle(user))
		return FALSE

	var/turf/selected_turf = get_turf(user)
	if(!check_hole_spawn(selected_turf))
		user.balloon_alert(user, "нет места!")
		to_chat(user, span_warning("Недостаточно места для ямы! Требуется минимум 3 на 3 метра свободного пространства."))
		return FALSE

/obj/effect/proc_holder/spell/bingle/spawn_hole/cast(list/targets, mob/user = usr)
	spawn_hole(selected_turf, user)

/obj/effect/proc_holder/spell/bingle/spawn_hole/proc/check_hole_spawn(turf/selected_turf)
	for(var/turf/adjacent_turf as anything in RANGE_TURFS(1, selected_turf))
		if(isnull(adjacent_turf) || adjacent_turf.density)
			return FALSE
	return TRUE

/obj/effect/proc_holder/spell/bingle/spawn_hole/proc/spawn_hole(turf/selected_turf, mob/living/user)
	var/datum/antagonist/bingle/bingle_datum = user.mind?.has_antag_datum(/datum/antagonist/bingle)
	if(!bingle_datum)
		return

	if(!selected_turf)
		user.balloon_alert(user, "нету пола!")
		to_chat(user, span_notice("Под вами нету пола!"))
		return

	var/obj/structure/bingle_hole/hole = new(selected_turf)

	// Complete the bingle lord objective
	var/datum/objective/bingle_lord/lord_obj = bingle_datum.objectives[1]
	lord_obj.completed = TRUE

	// Register the pit in the team, give the second obj to the bingle lord
	var/datum/team/bingles/bingle_team = bingle_datum.bingle_team
	bingle_team.pit_check = hole
	bingle_datum.give_objectives()

	// Register the team in the pit
	hole.bingle_team = bingle_datum.get_team()
	qdel(src)
