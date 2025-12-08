
/datum/hud/swarmer/New(mob/owner)
	..()
	var/atom/movable/screen/using

	mymob.healthdoll = new /atom/movable/screen/healthdoll/living(null, src)
	infodisplay += mymob.healthdoll

	using = new /atom/movable/screen/act_intent/swarmer(null, src)
	using.icon_state = mymob.a_intent
	static_inventory += using
	action_intent = using

