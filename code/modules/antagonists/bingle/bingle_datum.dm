/datum/antagonist/bingle
	name = "Bingle"
	roundend_category = "bingles"
	job_rank = ROLE_BINGLE
	antag_hud_name = "hudbingle"

/datum/antagonist/bingle/greet()
	var/list/messages = list()
	messages.Add(span_danger("<center>Вы — Бингл!</center>"))
	messages.Add("<center>Работайте сообща, помогайте своим братьям, разбирайте станцию, тащите экипаж в яму, сделайте из этой станции одну большую дыру!</center>")
	SEND_SOUND(owner.current, sound('sound/ambience/antag/bingle.ogg'))
	return messages

/datum/antagonist/bingle/give_objectives()
	if(!team)
		return
	var/datum/team/bingles/bingle_team = team
	if(!bingle_team.pit_check)
		add_objective(/datum/objective/bingle_lord)
		return
	var/datum/objective/bingle/bingle_obj = add_objective(/datum/objective/bingle)
	bingle_obj.pit_check = bingle_team.pit_check
