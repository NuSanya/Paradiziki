/datum/team/bingles
	name = "Бинглы"
	antag_datum_type = /datum/antagonist/bingle
	var/obj/structure/bingle_hole/pit_check

/datum/team/bingles/Destroy(force)
	pit_check = null
	return ..()
