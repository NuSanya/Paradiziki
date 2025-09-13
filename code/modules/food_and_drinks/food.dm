/**
 * # Food Item
 *
 * Base class for all food items that can contain reagents.
 *
 * Handles food-specific behavior including consumption, taste preferences,
 * ant attraction, and dirt-based poisoning. Provides methods for checking
 * species-specific food preferences and generating appropriate messages.
 */

/// Message templates for when a species HATES a food type
#define HATE_MESSAGES list("Что это было?! Я ненавижу <b>$TYPE</b>, я же $ASPECIES!", "Это было ужасно! Как уважающий себя $ASPECIES, я не могу есть <b>$TYPE</b>.", "Боже, это было опасно! <b>$CAPITALTYPE</b> $IS вредно для $PLURALSPECIES!")
/// Message templates for when a species DISLIKES a food type
#define DISLIKE_MESSAGES list("Не очень вкусно. Мне, как $ASPECIES, лучше избегать <b>$TYPE</b>.", "<b>$CAPITALTYPE</b> $IS не лучшая еда для $PLURALSPECIES. Больше не буду это есть.", "Фу. <b>$CAPITALTYPE</b> $IS не то, что должен есть $ASPECIES.")
/// Message templates for when a species LOVES a food type
#define LOVE_MESSAGES list("Восхитительно! Обожаю <b>$TYPE</b>!", "Ням. Я создан, чтобы есть <b>$TYPE</b>.", "Обожаю этот вкус. <b>$CAPITALTYPE</b> $IS прекрасно.", "<b>$CAPITALTYPE</b> $IS потрясающе. Надо есть это чаще.")

/// Range (in tiles) to search for dirt around food items
#define DIRT_CHECK_RANGE 2
/// Probability increase per dirt object found within range (percentage points)
#define DIRT_SCALING 10

/obj/item/reagent_containers/food
	possible_transfer_amounts = null
	volume = 50
	visible_transfer_rate = FALSE
	righthand_file = 'icons/mob/inhands/foods_righthand.dmi'
	lefthand_file = 'icons/mob/inhands/foods_lefthand.dmi'
	resistance_flags = FLAMMABLE
	container_type = INJECTABLE
	light_system = MOVABLE_LIGHT
	light_on = FALSE


	/// Color used for sandwich fillings
	var/filling_color = "#FFFFFF"
	/// Junk food factor that lowers human satiety
	var/junkiness = 0
	/// Amount consumed per bite
	var/bitesize = 2
	/// Whether this food has special eating effects
	var/has_special_eating_effects = FALSE
	/// Time taken to eat this food
	var/eat_time = 0 SECONDS
	/// Sound played when consumed
	var/consume_sound = 'sound/items/eatfood.ogg'
	/// How reagents are applied (ingestion)
	var/apply_type = REAGENT_INGEST
	/// Method description for applying reagents
	var/apply_method = "проглоти"
	/// Efficiency of reagent transfer
	var/transfer_efficiency = 1.0
	/// Bypass forced feeding delay
	var/instant_application = 0
	/// Whether taste can be detected when eating
	var/can_taste = TRUE
	/// Whether ants are attracted to this food
	var/antable = TRUE
	/// Last known location of the food for ant tracking
	var/ant_location = null
	/// Last time ant check was performed
	var/last_ant_time = 0
	/// Bitmask representing food types (meat, vegetables, etc.)
	var/foodtype = NONE
	/// Last time food preference check was performed
	var/last_check_time
	/// Whether eating this food should be logged
	var/log_eating = FALSE
	/// Whether this food can be poisoned by nearby dirt
	var/based_on_dirt_poisoning = TRUE

/obj/item/reagent_containers/food/Initialize(mapload)
	. = ..()
	pixel_x = rand(-5, 5) //Randomizes postion
	pixel_y = rand(-5, 5)
	if(antable)
		START_PROCESSING(SSobj, src)
		ant_location = get_turf(src)
		last_ant_time = world.time

/obj/item/reagent_containers/food/Destroy()
	ant_location = null
	if(isprocessing)
		STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/reagent_containers/food/process()
	if(!antable)
		return PROCESS_KILL
	if(world.time > last_ant_time + 5 MINUTES)
		check_for_ants()

/obj/item/reagent_containers/food/set_APTFT()
	set hidden = TRUE
	..()

/obj/item/reagent_containers/food/empty()
	set hidden = TRUE
	..()

/obj/item/reagent_containers/food/examine(mob/user)
	. = ..()
	if(foodtype & MEAT)
		. += "<span class='notice'>It contains meat.</span>"
	if(foodtype & VEGETABLES)
		. += "<span class='notice'>It contains vegetables.</span>"
	if(foodtype & RAW)
		. += "<span class='notice'>It is not properly cooked.</span>"
	if(foodtype & JUNKFOOD)
		. += "<span class='notice'>It is junkfood.</span>"
	if(foodtype & GRAIN)
		. += "<span class='notice'>It is made of grain.</span>"
	if(foodtype & FRUIT)
		. += "<span class='notice'>It contains fruits.</span>"
	if(foodtype & DAIRY)
		. += "<span class='notice'>It contains dairy.</span>"
	if(foodtype & FRIED)
		. += "<span class='notice'>It is fried.</span>"
	if(foodtype & SUGAR)
		. += "<span class='notice'>It is sugary.</span>"
	if(foodtype & EGG)
		. += "<span class='notice'>It contains eggs.</span>"
	if(foodtype & GROSS)
		. += "<span class='notice'>This is pure garbage.</span>"
	if(foodtype & TOXIC)
		. += "<span class='notice'>This is straight up poisonous.</span>"
	if(user.can_see_food()) //Show each individual reagent
		. += "<span class='notice'>It contains:</span>"
		for(var/I in reagents.reagent_list)
			var/datum/reagent/R = I
			. += "<span class='notice'>[R.volume] units of [R.name]</span>"

/**
 * Check for ant attraction to this food item
 *
 * Determines if conditions are suitable for ants to be attracted to the food
 * and creates ant decals with a chance if the food has been in the same location.
 * Also adds ants reagent to make the food inedible and updates description.
 */
/obj/item/reagent_containers/food/proc/check_for_ants()
	var/turf/T = get_turf(src)
	if(isturf(loc) && (T.temperature in 280 to 325) && !locate(/obj/structure/table) in T)
		if(ant_location == T)
			if(prob(15))
				if(!locate(/obj/effect/decal/ants) in T)
					new /obj/effect/decal/ants(T)
					antable = FALSE
					desc += " It appears to be infested with space ants. Yuck!"
					reagents.add_reagent("ants", 1) // Don't eat things with ants in i you weirdo.
		else
			ant_location = T

	last_ant_time = world.time

/**
 * Check if food is poisoned by nearby dirt
 *
 * Calculates the probability of food poisoning based on nearby dirt objects
 * within the defined range. Vendor junk food and items not based on dirt
 * poisoning are excluded from this check.
 *
 * Returns:
 * * TRUE - If food is determined to be poisoned
 * * FALSE - If food is not poisoned or exempt from checking
 */
/obj/item/reagent_containers/food/proc/check_for_dirt_poisoning()
	if(!antable) // basically check for vendor junk food
		return
	if(!based_on_dirt_poisoning)
		return

	var/poisoning_chance = 0
	var/turf/center_turf = get_turf(src)
	for(var/obj/effect/decal/cleanable/dirt in range(DIRT_CHECK_RANGE, center_turf))
		poisoning_chance += DIRT_SCALING

	if(!prob(poisoning_chance))
		return

	return TRUE

/**
 * Check if a mob likes this food based on species preferences
 *
 * Determines a mob's reaction to food based on their species' food preferences.
 * Adjusts disgust level accordingly and displays appropriate messages.
 * Only checks every 2 seconds to prevent spam.
 *
 * Arguments:
 * * fraction - The fraction of food consumed (0-1)
 * * M - The mob consuming the food
 */
/obj/item/reagent_containers/food/proc/check_liked(fraction, mob/M)
	if(last_check_time + 2 SECONDS < world.time)
		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			if(foodtype & H.dna.species.toxic_food)
				var/type_string = matched_food_type(foodtype & H.dna.species.toxic_food)
				to_chat(H, span_warning("[format_message(type_string, HATE_MESSAGES, H.dna.species)]"))

				H.AdjustDisgust((25 + 30 * fraction) STATUS_EFFECT_CONSTANT)
			if(foodtype & H.dna.species.disliked_food)
				var/type_string = matched_food_type(foodtype & H.dna.species.disliked_food)
				to_chat(H, span_warning("[format_message(type_string, DISLIKE_MESSAGES, H.dna.species)]"))

				H.AdjustDisgust((15 + 16 * fraction) STATUS_EFFECT_CONSTANT)
			if(foodtype & H.dna.species.liked_food)
				var/type_string = matched_food_type(foodtype & H.dna.species.liked_food)
				to_chat(H, span_notice("[format_message(type_string, LOVE_MESSAGES, H.dna.species)]"))

				H.AdjustDisgust((-12 + -8 * fraction) STATUS_EFFECT_CONSTANT)
			last_check_time = world.time

/**
 * Format species-specific food preference messages
 *
 * Replaces template variables in message strings with appropriate values
 * based on food type and species information.
 *
 * Arguments:
 * * type - The food type string to be formatted
 * * messages - List of possible message templates
 * * species - The species datum for formatting species-specific text
 *
 * Returns:
 * * Formatted message string with all template variables replaced
 */
/obj/item/reagent_containers/food/proc/format_message(type, list/messages, datum/species/species)
	var/plural = cmptext(type[length(type)], "s") ? "are" : "is"

	var/with_type = replacetext(pick(messages), "$TYPE", type)
	var/with_capital_type = replacetext(with_type, "$CAPITALTYPE", capitalize(type))
	var/with_species = replacetext(with_capital_type, "$SPECIES", species.name)
	var/with_plural_species = replacetext(with_species, "$PLURALSPECIES", species.name_plural)
	var/with_a_species = replacetext(with_plural_species, "$ASPECIES", "[species.a] [species.name]")
	return replacetext(with_a_species, "$IS", plural)

/**
 * Handle special effects when mob eats this food
 *
 * Placeholder proc for food-specific effects when consumed by a mob.
 * Should be overridden by specific food types for custom behavior.
 *
 * Arguments:
 * * user - The mob eating the food
 */
/obj/item/reagent_containers/food/proc/on_mob_eating_effect(mob/user)
	return

/**
 * Match food flags to readable food type strings
 *
 * Converts a bitmask of food types into a human-readable string
 * describing the food type for use in preference messages.
 *
 * Arguments:
 * * matching_flags - Bitmask of food types (MEAT, VEGETABLES, etc.)
 *
 * Returns:
 * * Readable food type string appropriate for message display
 */
/obj/item/reagent_containers/food/proc/matched_food_type(matching_flags)
	if(matching_flags & MEAT)
		return pick("meat", "flesh", "dead animals")
	if(matching_flags & VEGETABLES)
		return pick("vegetables", "veggies")
	if(matching_flags & RAW)
		return pick("raw food", "uncooked food", "tartare")
	if(matching_flags & FRUIT)
		return "fruit"
	if(matching_flags & DAIRY)
		return "dairy"
	if(matching_flags & FRIED)
		return pick("fried food", "deep fried stuff")
	if(matching_flags & ALCOHOL)
		return pick("alcohol", "booze")
	if(matching_flags & SUGAR)
		return pick("sugary food", "sweets")
	if(matching_flags & GRAIN)
		return pick("grain products", "carbs")
	if(matching_flags & EGG)
		return pick("eggs")
	if(matching_flags & GROSS)
		return pick("gross stuff", "garbage")
	if(matching_flags & TOXIC)
		return pick("toxic garbage", "toxins", "literally poison")
	if(matching_flags & JUNKFOOD)
		return "junk food"

#undef DIRT_SCALING
#undef DIRT_CHECK_RANGE
#undef HATE_MESSAGES
#undef DISLIKE_MESSAGES
#undef LOVE_MESSAGES
