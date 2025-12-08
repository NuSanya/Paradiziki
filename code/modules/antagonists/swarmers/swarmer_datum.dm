/datum/antagonist/swarmer
	name = "Swarmer"
	roundend_category = "swarmers"
	job_rank = ROLE_SWARMER
	special_role = SPECIAL_ROLE_SWARMER
	//wiki_page_name = "Swarmer"
	//russian_wiki_name = "Свармер"
	show_in_roundend = FALSE
	show_in_orbit = FALSE
	antag_menu_name = "Свармер"
	var/swarmer_class_info = "Если ты это видишь, это баг."

/datum/antagonist/swarmer/on_gain()
	if(!isswarmer(owner.current))
		stack_trace("This antag datum cannot be attached to a mob of this type.")
	var/mob/living/simple_animal/hostile/swarmer/swarmer = owner.current
	swarmer_class_info = span_bold("Ваш класс: [initial(swarmer.name)]!") + "\n" + swarmer.swarmer_class_info
	. = ..()

/*
/datum/antagonist/swarmer/give_objectives()
	if(!swarmer_team.main_objective)
		terror_team.other_target = new
		terror_team.other_target.owner = team
		terror_team.other_target.generate_text(terror_team)
	add_objective(terror_team.other_target)
	terror_team.other_target.check_completion()
*/

/datum/antagonist/swarmer/roundend_report_header()
	return

/datum/antagonist/swarmer/greet()
	var/list/messages = list()
	messages.Add(span_danger("Вы — Свармер!\n"))
	messages.Add(span_bold("Цели роя:"))
	messages.Add("1. Обеспечивать безопасность роя и потреблять ресурсы, пока они не иссякнут.")
	messages.Add("2. Сохранять местность пригодной для последующего вторжения; избегать действий, делающих её опасной или необитаемой.")
	messages.Add("3. Биологические ресурсы будут полезнее будучи живыми, старайтесь не причинять им вред, по мере возможности.\n")
	messages.Add(span_bold("Информация по интентам"))
	messages.Add("1. Интент \"Помощь\", или же \"первый\", используется для взаимодействия с объектами \"Свармеров\".")
	messages.Add("2. Интент \"Разбор\", или же \"второй\", используется для разбора структур и сбора материалов.")
	messages.Add("3. Интент \"Ремонт\", или же \"третий\", используется для починки других \"Свармеров\" и объектов. Чинить самого себя нельзя.")
	messages.Add("4. Интент \"Строительство\", или же \"четвёртый\", используется только классом \"Строитель\".\n")
	messages.Add(span_bold("Полезная информация"))
	messages.Add("Все ваши выстрелы и атаки, включая от построек, накладывают на цель блокировку лечения стамины.")
	messages.Add("Используя Ctrl + Click на цели, вы сможете начать процесс телепортации, что может обеспечить вас источником органических ресурсов.\n")
	messages.Add("[swarmer_class_info]\n")
	SEND_SOUND(owner.current, sound('sound/effects/bin_close.ogg'))
	return messages
