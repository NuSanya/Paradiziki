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


/obj/effect/proc_holder/spell/bingle
	name = "Zuzya"
	desc = "Напишите баг-репорт, если вы это увидели."
	action_icon = 'icons/mob/bingle/binglepit.dmi'
	clothes_req = FALSE
	human_req = FALSE

/obj/effect/proc_holder/spell/bingle/spawn_hole
	name = "Spawn Bingle Pit"
	desc = "Создаёт яму. Яму надо КОРМИТЬ."
	action_icon_state = "binglepit"
	create_attack_logs = FALSE
	create_custom_logs = TRUE
	base_cooldown = 10 SECONDS

/obj/effect/proc_holder/spell/bingle/spawn_hole/write_custom_logs(list/targets, mob/user)
	user.create_log(MISC_LOG, "Summoned bingle pit with spell [name]")

/obj/effect/proc_holder/spell/bingle/spawn_hole/create_new_targeting()
	var/datum/spell_targeting/aoe/turf/T = new()
	T.range = 1
	return T

/obj/effect/proc_holder/spell/bingle/spawn_hole/can_cast(mob/living/user = usr, charge_check = TRUE, show_message = FALSE)
	if(!isbingle(user))
		return FALSE
	. = ..()

/obj/effect/proc_holder/spell/bingle/spawn_hole/cast(list/targets, mob/user = usr)
	var/turf/selected_turf = get_turf(user)
	if(!check_hole_spawn(selected_turf))
		to_chat(user, span_warning("Это место не имеет достаточно места для ямы! Требуется минимум 3 на 3 метра свободного пространства."))
		return FALSE
	spawn_hole(selected_turf, user)

/obj/effect/proc_holder/spell/bingle/spawn_hole/proc/check_hole_spawn(turf/selected_turf)
	for(var/turf/adjacent_turf as anything in RANGE_TURFS(1, selected_turf))
		if(isnull(adjacent_turf) || adjacent_turf.density)
			return FALSE
	return TRUE

/obj/effect/proc_holder/spell/bingle/spawn_hole/proc/spawn_hole(turf/selected_turf, mob/living/user)
    var/datum/antagonist/bingle/bingle_datum = user.mind?.has_antag_datum(/datum/antagonist/bingle)
    if(!selected_turf)
        to_chat(user, span_notice("Под вами нету пола!"))
        return
    var/obj/structure/bingle_hole/hole = new(selected_turf)
    bingle_datum.pit_check = hole
    // Register the team in the pit
    hole.bingle_team = bingle_datum.get_team()
    qdel(src)
