/// Called when swarmer clicks this atom.
/atom/proc/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	S.disintegrate(src)
	return TRUE

/atom/movable/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	if(!simulated)
		return FALSE
	return ..()

/obj/effect/mob_spawn/swarmer/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	S.Integrate(src)
	return FALSE

/obj/effect/mob_spawn/swarmer/integrate_amount()
	return 100

/turf/simulated/wall/indestructible/swarmer_act()
	return FALSE

/obj/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	if(resistance_flags & INDESTRUCTIBLE)
		to_chat(S, span_warning("Обнаружены высокоценные материалы, переработка [src] будет нерациональной. Прерываю."))
		return FALSE
	return ..()

/obj/item/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	return S.Integrate(src)

/obj/item/gun/swarmer_act()
	return FALSE

/turf/simulated/floor/swarmer_act()
	return FALSE

/obj/structure/lattice/catwalk/swarmer_catwalk/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Мы создали это для собственного использования. Прерываю."))
	return FALSE

/obj/effect/swarmer_act()
	return FALSE

/obj/effect/decal/cleanable/robot_debris/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	S.disintegrate(src)
	qdel(src)
	return TRUE

/obj/structure/flora/swarmer_act()
	return FALSE

/turf/simulated/floor/lava/swarmer_act()
	if(!is_safe())
		new /obj/structure/lattice/catwalk/swarmer_catwalk(src)
	return FALSE

/obj/machinery/atmospherics/swarmer_act()
	return FALSE

/obj/structure/disposalpipe/swarmer_act()
	return FALSE

/obj/machinery/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	S.dismantle_machine(src)
	return TRUE

/obj/machinery/light/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	S.disintegrate(src)
	return TRUE

/obj/machinery/door/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	var/isonshuttle = istype(get_area(src), /area/shuttle)
	for(var/turf/T in range(1, src))
		var/area/A = get_area(T)
		if(isspaceturf(T) || (!isonshuttle && (istype(A, /area/shuttle) || isspacearea(A))) || (isonshuttle && !istype(A, /area/shuttle)))
			to_chat(S, span_warning("Разрушение этого объекта может привести к разгерметизации. Прерываю."))
			S.GiveTarget(null)
			return FALSE
		else if(istype(A, /area/engineering/supermatter))
			to_chat(S, span_warning("Нарушение содержания кристалла суперматерии не принесёт нам пользы. Прерываю."))
			S.GiveTarget(null)
			return FALSE
	S.disintegrate(src)
	return TRUE

/obj/machinery/camera/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	S.disintegrate(src)
	toggle_cam(S, 0)
	return TRUE

/obj/structure/particle_accelerator/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Нарушение работы энергосистемы не принесёт нам пользы. Прерываю."))
	return FALSE

/obj/machinery/particle_accelerator/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Нарушение работы энергосистемы не принесёт нам пользы. Прерываю."))
	return FALSE

/obj/machinery/field/generator/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	if(!active)
		S.disintegrate(src)
		return TRUE
	to_chat(S, span_warning("Уничтожение этого объекта может создать неблагоприятную зону. Прерываю."))
	return FALSE

/obj/machinery/gravity_generator/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	S.disintegrate(src)
	return TRUE

/obj/machinery/vending/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	S.disintegrate(src)
	return TRUE

/obj/machinery/turretid/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	S.disintegrate(src)
	return TRUE

/obj/machinery/nuclearbomb/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Уничтожение этого устройства приведёт к ликвидации всего в зоне. Прерываю."))
	return FALSE

/obj/machinery/r_n_d/server/core/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот аппарат следует сохранить, он будет полезным ресурсом для наших создателей в будущем. Прерываю."))
	return FALSE

/obj/machinery/r_n_d/server/robotics/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот аппарат следует сохранить, он будет полезным ресурсом для наших создателей в будущем. Прерываю."))
	return FALSE

/obj/effect/rune/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Поиск... сбой сенсора! Цель потеряна. Прерываю."))
	return FALSE

/obj/structure/reagent_dispensers/fueltank/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Уничтожение этого объекта вызовет цепную реакцию. Прерываю."))
	return FALSE

/obj/structure/cable/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Нарушение работы энергосистемы не принесёт нам пользы. Прерываю."))
	return FALSE

/obj/machinery/portable_atmospherics/canister/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Уничтожение этого объекта может создать неблагоприятную зону. Прерываю."))
	return FALSE

/obj/machinery/tcomms/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот ретранслятор связи следует сохранить, он будет полезным ресурсом для наших создателей в будущем. Прерываю."))
	return FALSE

/obj/machinery/message_server/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот ретранслятор связи следует сохранить, он будет полезным ресурсом для наших создателей в будущем. Прерываю."))
	return FALSE

/obj/machinery/blackbox_recorder/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот аппарат записал большой объём данных о структуре и её обитателях, он будет полезен нашим создателям в будущем. Прерываю."))
	return FALSE

/obj/machinery/power/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Нарушение работы энергосистемы не принесёт нам пользы. Прерываю."))
	return FALSE

/obj/machinery/gateway/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот источник блюспейса будет важен для нас позже. Прерываю."))
	return FALSE

/obj/machinery/cryopod/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот криогенный сон следует сохранить, он будет полезным ресурсом для наших создателей в будущем. Прерываю."))
	return FALSE

/obj/structure/cryofeed/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот криогенный питатель следует сохранить, он будет полезным ресурсом для наших создателей в будущем. Прерываю."))
	return FALSE

/obj/machinery/computer/cryopod/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот компьютер управления криоподом следует сохранить, он содержит полезные предметы и информацию об обитателях. Прерываю."))
	return FALSE

/obj/structure/spacepoddoor/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Нарушение этого энергетического поля перегрузит нас. Прерываю."))
	return FALSE

/turf/simulated/wall/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	var/isonshuttle = istype(loc, /area/shuttle)
	for(var/turf/T in range(1, src))
		var/area/A = get_area(T)
		if(isspaceturf(T) || (!isonshuttle && (istype(A, /area/shuttle) || isspacearea(A))) || (isonshuttle && !istype(A, /area/shuttle)))
			to_chat(S, span_warning("Разрушение этого объекта может привести к разгерметизации. Прерываю."))
			S.GiveTarget(null)
			return TRUE
		else if(istype(A, /area/engineering/supermatter))
			to_chat(S, span_warning("Нарушение содержания кристалла суперматерии не принесёт нам пользы. Прерываю."))
			S.GiveTarget(null)
			return TRUE
	return ..()

/turf/simulated/mineral/ancient/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	var/isonshuttle = istype(loc, /area/shuttle)
	for(var/turf/T in range(1, src))
		var/area/A = get_area(T)
		if(isspaceturf(T) || (!isonshuttle && (istype(A, /area/shuttle) || isspacearea(A)) || (isonshuttle && !istype(A, /area/shuttle)))
			to_chat(S, span_warning("Разрушение этого объекта может привести к разгерметизации. Прерываю."))
			S.GiveTarget(null)
			return TRUE
	return ..()

/obj/structure/window/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	var/isonshuttle = istype(get_area(src), /area/shuttle)
	for(var/turf/T in range(1, src))
		var/area/A = get_area(T)
		if(isspaceturf(T) || (!isonshuttle && (istype(A, /area/shuttle) || isspacearea(A))) || (isonshuttle && !istype(A, /area/shuttle)))
			to_chat(S, span_warning("Разрушение этого объекта может привести к разгерметизации. Прерываю."))
			S.GiveTarget(null)
			return TRUE
		else if(istype(A, /area/engineering/supermatter))
			to_chat(S, span_warning("Нарушение содержания кристалла суперматерии не принесёт нам пользы. Прерываю."))
			S.GiveTarget(null)
			return TRUE
	return ..()

/obj/structure/holosign/barrier/atmos/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	var/isonshuttle = istype(get_area(src), /area/shuttle)
	for(var/turf/T in range(1, src))
		var/area/A = get_area(T)
		if(isspaceturf(T) || (!isonshuttle && (istype(A, /area/shuttle) || isspacearea(A))) || (isonshuttle && !istype(A, /area/shuttle)))
			to_chat(S, span_warning("Разрушение этого объекта может привести к разгерметизации. Прерываю."))
			S.GiveTarget(null)
			return TRUE
		else if(istype(A, /area/engineering/supermatter))
			to_chat(S, span_warning("Нарушение содержания кристалла суперматерии не принесёт нам пользы. Прерываю."))
			S.GiveTarget(null)
			return TRUE
	return ..()

/mob/living/simple_animal/slime/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот биологический ресурс каким-то образом сопротивляется нашему блюспейс-передатчику. Прерываю."))
	return FALSE

/obj/structure/shuttle/engine/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот шаттл может быть важен для нас позже. Прерываю."))
	return FALSE

/obj/structure/lattice/catwalk/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	var/turf/here = get_turf(src)
	for(var/A in here.contents)
		var/obj/structure/cable/C = A
		if(istype(C))
			to_chat(S, span_warning("Нарушение работы энергосистемы не принесёт нам пользы. Прерываю."))
			return FALSE
	return ..()

/obj/item/deactivated_swarmer/integrate_amount()
	return 100

/obj/machinery/hydroponics/soil/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот объект содержит недостаточно материалов для работы."))
	return FALSE

/obj/machinery/field/containment/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, span_warning("Этот объект не содержит твёрдой материи. Прерываю."))
	return FALSE
