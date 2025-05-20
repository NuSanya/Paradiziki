//His Grace is a very special weapon granted only to traitor chaplains and civilians.
//When awakened, He thirsts for blood and begins ticking a "bloodthirst" counter.
//The wielder of His Grace is immune to stuns and gradually heals.
//If the wielder fails to feed His Grace in time, He will devour them and become incredibly aggressive.
//Leaving His Grace alone for some time will reset His thirst and put Him to sleep.
//Using His Grace effectively requires extreme speed and care.
/obj/item/his_grace
	name = "artistic toolbox"
	desc = "Покрашенный в ярко-зелёные цвета тулбокс. От одного его вида становится страшно."
	ru_names = list(
		NOMINATIVE = "артистический ящик для инструментов",
		GENITIVE = "артистического ящика для инструментов",
		DATIVE = "артистическому ящику для инструментов",
		ACCUSATIVE = "артистический ящик для инструментов",
		INSTRUMENTAL = "артистическим ящиком для инструментов",
		PREPOSITIONAL = "артистическом ящике для инструментов"
	)
	icon = 'icons/goonstation/objects/objects.dmi'
	icon_state = "green"
	item_state = "toolbox_green"
	lefthand_file = 'icons/goonstation/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/goonstation/mob/inhands/items_righthand.dmi'
	w_class = WEIGHT_CLASS_GIGANTIC
	force = 12
	armour_penetration = 0
	attack_verb = list("заробастил", "сокрушил")
	hitsound = 'sound/weapons/smash.ogg'
	actions_types = list(/datum/action/item_action/toggle)
	drop_sound = 'sound/items/handling/toolbox_drop.ogg'
	pickup_sound = 'sound/items/handling/toolbox_pickup.ogg'
	var/awakened = FALSE
	var/bloodthirst = HIS_GRACE_SATIATED
	var/prev_bloodthirst = HIS_GRACE_SATIATED
	var/force_bonus = 0
	var/ascended = FALSE
	var/victims_needed = 20
	var/ascend_bonus = 15

/obj/item/his_grace/ui_action_click(mob/user, datum/action/action, leftclick)
	if(user.has_status_effect(STATUS_EFFECT_HISGRACE))
		var/obj/item/his_grace/M = user.get_active_hand()
		if(istype(M))
			var/prev_has = HAS_TRAIT_FROM(src, TRAIT_NODROP, HIS_GRACE_TRAIT)
			if(prev_has)
				REMOVE_TRAIT(src, TRAIT_NODROP, HIS_GRACE_TRAIT)
			else
				ADD_TRAIT(src, TRAIT_NODROP, HIS_GRACE_TRAIT)
			to_chat(user, span_warning("[declent_ru(NOMINATIVE)] [prev_has ? "освобождает вашу руку" : "привязывается к вашей руке"]!"))
	else
		to_chat(user, span_warning("Вы не совсем понимаете, что с этим делать."))

/obj/item/his_grace/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSprocessing, src)
	GLOB.poi_list |= src
	RegisterSignal(src, COMSIG_MOVABLE_POST_THROW, PROC_REF(move_gracefully))
	update_appearance()

/obj/item/his_grace/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	GLOB.poi_list.Remove(src)
	for(var/mob/living/L in src)
		L.forceMove(get_turf(src))
	return ..()

/obj/item/his_grace/update_icon_state()
	icon_state = ascended ? "gold" : "green"
	item_state = ascended ? "toolbox_gold" : "toolbox_green"
	return ..()

/obj/item/his_grace/update_overlays()
	. = ..()
	if(ascended)
		. += "triple_latch"
	else if(awakened)
		. += "single_latch_open"
	else
		. += "single_latch"

/obj/item/his_grace/attack_self(mob/living/user)
	if(!awakened)
		INVOKE_ASYNC(src, PROC_REF(awaken), user)

/obj/item/his_grace/attack(mob/living/M, mob/user)
	var/mob/living/carbon/CM
	if(ishuman(M))
		CM = M
	if(awakened && (M.stat || CM?.IsStamcrited() || CM?.health <= HEALTH_THRESHOLD_CRIT)) //change because carbons on paradise are very lively
		consume(M)
	else
		..()

/obj/item/his_grace/CtrlClick(mob/user)
	//you can't pull his grace
	return NONE

/obj/item/his_grace/examine(mob/user)
	. = ..()
	if(awakened)
		switch(bloodthirst)
			if(HIS_GRACE_SATIATED to HIS_GRACE_PECKISH)
				. += span_his_grace("[declent_ru(NOMINATIVE)] не очень голоден. Пока что.")
			if(HIS_GRACE_PECKISH to HIS_GRACE_HUNGRY)
				. += span_his_grace("[declent_ru(NOMINATIVE)] слегка проголодался.")
			if(HIS_GRACE_HUNGRY to HIS_GRACE_FAMISHED)
				. += span_his_grace("[declent_ru(NOMINATIVE)] уже довольно голоден.")
			if(HIS_GRACE_FAMISHED to HIS_GRACE_STARVING)
				. += span_his_grace("[declent_ru(NOMINATIVE)] уже не скрывает, как пускает слюни при виде вас. Будьте осторожны.")
			if(HIS_GRACE_STARVING to HIS_GRACE_CONSUME_OWNER)
				. += span_his_grace("Вы играете с огнём. [declent_ru(NOMINATIVE)] в шаге от того, чтобы вас сожрать.")
			if(HIS_GRACE_CONSUME_OWNER to HIS_GRACE_FALL_ASLEEP)
				. += span_his_grace("[declent_ru(NOMINATIVE)] яростно трясётся, на сводя с вас глаз.")
	else
		. += span_his_grace("Защёлка [declent_ru(GENITIVE)] закрыта.")

/obj/item/his_grace/relaymove(mob/living/user, direction) //Allows changelings, etc. to climb out of Him after they revive, provided He isn't active
	if(!awakened)
		user.forceMove(get_turf(src))
		user.visible_message(span_warning("[user] выкарабкивается из [declent_ru(GENITIVE)]!"), span_notice("Вы выбираетесь из [declent_ru(GENITIVE)]!"))

/obj/item/his_grace/process(seconds_per_tick)
	if(!bloodthirst)
		drowse()
		return
	if(bloodthirst < HIS_GRACE_CONSUME_OWNER && !ascended)
		adjust_bloodthirst((1 + FLOOR(LAZYLEN(contents) * 0.4, 1)) * seconds_per_tick) //Maybe adjust this?
	else
		adjust_bloodthirst(1 * seconds_per_tick) //don't cool off rapidly once we're at the point where His Grace consumes all.
	var/mob/living/master = get_atom_on_turf(src, /mob/living)
	if(!isnull(master) && istype(master, /mob/living) && master.is_in_hands(src)) //required type check
		switch(bloodthirst)
			if(HIS_GRACE_CONSUME_OWNER to HIS_GRACE_FALL_ASLEEP)
				master.visible_message(span_boldwarning("[declent_ru(NOMINATIVE)] натравляется на [master]!"), span_his_grace("[declent_ru(NOMINATIVE)] натравляется на вас!"))
				do_attack_animation(master, null, src)
				master.emote("scream")
				master.remove_status_effect(/datum/status_effect/his_grace)
				REMOVE_TRAIT(src, TRAIT_NODROP, HIS_GRACE_TRAIT)
				master.Paralyse(60 SECONDS)
				master.adjustBruteLoss(master.maxHealth)
				playsound(master, 'sound/effects/splat.ogg', 100, FALSE)
			else
				master.apply_status_effect(/datum/status_effect/his_grace)
		return
	forceMove(get_turf(src)) //no you can't put His Grace in a locker you just have to deal with Him
	if(bloodthirst < HIS_GRACE_CONSUME_OWNER)
		return
	if(bloodthirst >= HIS_GRACE_FALL_ASLEEP)
		drowse()
		return
	var/list/targets = list()
	for(var/mob/living/L in oview(5, src))
		targets += L
	if(!LAZYLEN(targets))
		return
	var/mob/living/L = pick(targets)
	step_to(src, L)
	if(Adjacent(L))
		if(!L.stat)
			L.visible_message(span_warning("[declent_ru(NOMINATIVE)] бросается на [L]!"), span_his_grace("[declent_ru(NOMINATIVE)] бросается на вас!"))
			do_attack_animation(L, null, src)
			playsound(L, 'sound/weapons/smash.ogg', 50, TRUE)
			playsound(L, 'sound/weapons/bladeslice.ogg', 50, TRUE)
			L.adjustBruteLoss(force)
			adjust_bloodthirst(-5) //Don't stop attacking they're right there!
		else
			consume(L)

/obj/item/his_grace/proc/awaken(mob/user) //Good morning, Mr. Grace.
	if(awakened)
		return
	awakened = TRUE
	user.visible_message(span_boldwarning("[declent_ru(NOMINATIVE)] начинает яростно дребезжать. Он жаждет крови."), span_his_grace("Вы открываете защёлку [declent_ru(GENITIVE)]. Хорошая ли это была идея?."))
	name = "His Grace"
	desc = "Кровавый артефакт, рождённый скверной магией."
	ru_names = list(
		NOMINATIVE = "Его Светлость",
		GENITIVE = "Его Светлости",
		DATIVE = "Его Светлости",
		ACCUSATIVE = "Его Светлость",
		INSTRUMENTAL = "Его Светлостью",
		PREPOSITIONAL = "Его Светлости"
	)
	gender = MALE
	adjust_bloodthirst(1)
	force_bonus = HIS_GRACE_FORCE_BONUS * LAZYLEN(contents)
	armour_penetration = 50
	notify_ghosts(
		"[user.real_name] пробудил Его Светлость!",
		source = src,
		action = NOTIFY_FOLLOW,
		title = "Славься Его Светлость!",
		alert_overlay = image("icons/goonstation/objects/objects.dmi", "green4"),
		ghost_sound = 'sound/effects/pope_entry.ogg'
	)
	playsound(user, 'sound/effects/his_grace/his_grace_awaken.ogg', 100)
	update_appearance()
	move_gracefully()

/obj/item/his_grace/proc/move_gracefully()
	SIGNAL_HANDLER

	if(!awakened)
		return

	spasm_animation()

/obj/item/his_grace/proc/drowse() //Good night, Mr. Grace.
	if(!awakened || ascended)
		return
	var/turf/T = get_turf(src)
	T.visible_message(span_boldwarning("[declent_ru(NOMINATIVE)] медленно затихает и замирает. Защёлка [declent_ru(GENITIVE)] с громким щелчком захлопывается."))
	playsound(loc, 'sound/weapons/batonextend.ogg', 100, TRUE)
	name = initial(name)
	ru_names = initial(ru_names)
	desc = initial(desc)
	animate(src, transform=matrix())
	gender = initial(gender)
	force = initial(force)
	force_bonus = initial(force_bonus)
	armour_penetration = initial(armour_penetration)
	awakened = FALSE
	bloodthirst = 0
	update_appearance()

/obj/item/his_grace/proc/consume(mob/living/meal) //Here's your dinner, Mr. Grace.
	if(!meal)
		return
	var/victims = 0
	meal.visible_message(span_warning("[declent_ru(NOMINATIVE)] открывается нараспашку и пожирает [meal]!"), span_his_grace("[span_big("[declent_ru(NOMINATIVE)] пожирает вас!")]"))
	meal.adjustBruteLoss(200)
	meal.death()
	playsound(meal, 'sound/weapons/bladeslice.ogg', 75, TRUE)
	playsound(loc, 'sound/goonstation/misc/burp_alien.ogg', 50, 0)
	meal.forceMove(src)
	force_bonus += HIS_GRACE_FORCE_BONUS
	prev_bloodthirst = bloodthirst
	if(prev_bloodthirst < HIS_GRACE_CONSUME_OWNER)
		bloodthirst = max(LAZYLEN(contents), 1) //Never fully sated, and His hunger will only grow.
	else
		bloodthirst = HIS_GRACE_CONSUME_OWNER
	for(var/mob/living/C in contents)
		if(C.mind)
			victims++
	if(victims >= victims_needed)
		ascend()
	update_stats()

/obj/item/his_grace/proc/adjust_bloodthirst(amt)
	prev_bloodthirst = bloodthirst
	if(prev_bloodthirst < HIS_GRACE_CONSUME_OWNER && !ascended)
		bloodthirst = clamp(bloodthirst + amt, HIS_GRACE_SATIATED, HIS_GRACE_CONSUME_OWNER)
	else if(!ascended)
		bloodthirst = clamp(bloodthirst + amt, HIS_GRACE_CONSUME_OWNER, HIS_GRACE_FALL_ASLEEP)
	update_stats()

/obj/item/his_grace/proc/update_stats()
	var/mob/living/master = get_atom_on_turf(src, /mob/living)
	if(isnull(master))
		return
	switch(bloodthirst)
		if(HIS_GRACE_CONSUME_OWNER to HIS_GRACE_FALL_ASLEEP)
			if(HIS_GRACE_CONSUME_OWNER > prev_bloodthirst)
				master.visible_message(span_userdanger("[declent_ru(NOMINATIVE)] входит в ярость!"))
		if(HIS_GRACE_STARVING to HIS_GRACE_CONSUME_OWNER)
			if(HIS_GRACE_STARVING > prev_bloodthirst)
				master.visible_message(span_boldwarning("[declent_ru(NOMINATIVE)] адски голоден!"), span_his_grace("[span_big("Кровожадность [declent_ru(GENITIVE)] овладевает вами. [declent_ru(NOMINATIVE)] должен быть накормлен сейчас же, иначе будут последствия.\
				[force_bonus < 15 ? "И всё ещё, его сила растёт.":""]")]"))
				force_bonus = max(force_bonus, 15)
		if(HIS_GRACE_FAMISHED to HIS_GRACE_STARVING)
			if(HIS_GRACE_FAMISHED > prev_bloodthirst)
				master.visible_message(span_boldwarning("[declent_ru(NOMINATIVE)] очень голоден!"), span_his_grace("[span_big("Шипы пронзают вашу руку. [declent_ru(NOMINATIVE)] должен быть накормлен.\
				[force_bonus < 10 ? " Его сила растёт.":""]")]"))
				force_bonus = max(force_bonus, 10)
			if(prev_bloodthirst >= HIS_GRACE_STARVING)
				master.visible_message(span_warning("[declent_ru(NOMINATIVE)] довольно голоден!"), span_his_grace("Ваша кровожадность спадает."))
		if(HIS_GRACE_HUNGRY to HIS_GRACE_FAMISHED)
			if(HIS_GRACE_HUNGRY > prev_bloodthirst)
				master.visible_message(span_boldwarning("[declent_ru(NOMINATIVE)] проголодался!"), span_his_grace("[span_big("Вы чувствуете голод [declent_ru(GENITIVE)].\
				[force_bonus < 5 ? " Его сила растёт.":""]")]"))
				force_bonus = max(force_bonus, 5)
			if(prev_bloodthirst >= HIS_GRACE_FAMISHED)
				master.visible_message(span_warning("[declent_ru(NOMINATIVE)] незначительно голоден."), span_his_grace("Голод [declent_ru(GENITIVE)] незначительно спадает..."))
		if(HIS_GRACE_PECKISH to HIS_GRACE_HUNGRY)
			if(HIS_GRACE_PECKISH > prev_bloodthirst)
				master.visible_message(span_warning("[declent_ru(NOMINATIVE)] не против бы перекусить."), span_his_grace("[declent_ru(NOMINATIVE)] начинает голодать."))
			if(prev_bloodthirst >= HIS_GRACE_HUNGRY)
				master.visible_message(span_warning("[declent_ru(NOMINATIVE)] лишь слегка проголодался."), span_his_grace("Голод [declent_ru(GENITIVE)] незначительно спадает..."))
		if(HIS_GRACE_SATIATED to HIS_GRACE_PECKISH)
			if(prev_bloodthirst >= HIS_GRACE_PECKISH)
				master.visible_message(span_warning("[declent_ru(NOMINATIVE)] сыт."), span_his_grace("Голод [declent_ru(GENITIVE)] спадает..."))
	force = initial(force) + force_bonus

/obj/item/his_grace/proc/ascend()
	if(ascended)
		return
	var/mob/living/carbon/human/master = loc
	force_bonus += ascend_bonus
	desc = "Легендарный тулбокс, реликт Эпохи Трёх Сил. Его три застёжки сияют надписями «The Sun», «The Moon», «The Stars», а на гранях — таинственное «The World»"
	ascended = TRUE
	update_appearance()
	playsound(src, 'sound/effects/his_grace/his_grace_ascend.ogg', 100)
	if(istype(master))
		//master.update_held_items()
		master.visible_message(span_his_grace("[span_big("Боги наблюдают за тобой.")]"))
		name = "[master]'s mythical toolbox of three powers"
		ru_names = list(
			NOMINATIVE = "Мифический тулбокс трёх сил",
			GENITIVE = "Мифического тулбокса трёх сил",
			DATIVE = "Мифическому тулбоксу трёх сил",
			ACCUSATIVE = "Мифический тулбокс трёх сил",
			INSTRUMENTAL = "Мифическим тулбоксом трёх сил",
			PREPOSITIONAL = "Мифическом тулбоксе трёх сил"
		)
