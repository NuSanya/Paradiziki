/// Worst swarmer deconstruction speed modifier
#define SLOW_SWARMER_DISMANTLE_DELAY 15 SECONDS
/// Average swarmer deconstruction speed modifier
#define NORMAL_SWARMER_DISMANTLE_DELAY 8 SECONDS
/// Best swarmer deconstruction speed modifier
#define FAST_SWARMER_DISMANTLE_DELAY 3 SECONDS

/// How many inorganic resources are required to swap to this class (Note: Swapping from non-basic swarmer costs twice less)
#define GENERALIST_SWAP_COST 20
/// How many inorganic resources are required to swap to this class (Note: Swapping from non-basic swarmer costs twice less)
#define ROVER_SWAP_COST 18
/// How many inorganic resources are required to swap to this class (Note: Swapping from non-basic swarmer costs twice less)
#define COMBAT_SWAP_COST 30
/// How many inorganic resources are required to swap to this class (Note: Swapping from non-basic swarmer costs twice less)
/// If there are no builders, the swap cost is zero
#define BUILDER_SWAP_COST 20

/// How much swarmers and swarmer structures get damaged on emp
#define SWARMER_EMP_DAMAGE 25

/// How many inorganic resources does it cost to make a barricade
#define SWARMER_BLOCKADE_COST 7
/// How many inorganic resources does it cost to make a trap
#define SWARMER_TRAP_COST 3
/// How many inorganic resources does it cost to make a transport hub
#define SWARMER_HUB_COST 15
/// How many inorganic resources does it cost to make an organic processer
#define SWARMER_PROCESSER_COST 20
/// How many inorganic resources does it cost to make an organic analyzer
#define SWARMER_ANALYZER_COST 20

/// How much time does it take to make a barricade
#define SWARMER_BLOCKADE_BUILD_DELAY 2 SECONDS
/// How much time does it take to make a trap
#define SWARMER_TRAP_BUILD_DELAY 1 SECONDS
/// How much time does it take to make a hub
#define SWARMER_HUB_BUILD_DELAY 10 SECONDS

/// Cooldown of default swarmer projectile (used by /mob/living/simple_animal/hostile/swarmer/generalist&combat)
#define SWARMER_NORMAL_PROJECTILE_COOLDOWN 1 SECONDS
/// Cooldown of double swarmer projectile (used by /mob/living/simple_animal/hostile/swarmer/combat)
#define SWARMER_DOUBLE_PROJECTILE_COOLDOWN 2 SECONDS
/// Cooldown of strong swarmer projectile (used by /mob/living/simple_animal/hostile/swarmer/combat)
#define SWARMER_STRONG_PROJECTILE_COOLDOWN 2.5 SECONDS
/// Cooldown of sabotage swarmer projectile (used by /mob/living/simple_animal/hostile/swarmer/combat)
#define SWARMER_SABOTAGE_PROJECTILE_COOLDOWN 3 SECONDS

/// How long does it take for a swarmer to teleport through hubs (Note: Rovers take twice less time)
#define SWARMER_TELEPORT_DELAY(swarmer) (is_roverswarmer(swarmer) ? 4 SECONDS : 8 SECONDS)

/// How long does it take for a combat swarmer to switch modes
#define SWARMER_MODE_SWITCH_DELAY 1.5 SECONDS

/// How long does it take for swarmer to repair something (Builder swarmers take twice less time)
#define SWARMER_REPAIR_DELAY(swarmer) (is_builderswarmer(swarmer) ? 0.5 SECONDS : 1 SECONDS)
/// How much swarmer related stuff gets repaired by (Builder swarmer repair twice more)
#define SWARMER_REPAIR_AMOUNT(swarmer) (is_builderswarmer(swarmer) ? 30 : 15)
/// How many inorganic resources does it cost for swarmer to repair something
#define SWARMER_REPAIR_COST 0.5

/// How long does it take for a swarmer to send anything to processer/analyzer
#define SWARMER_SEND_ORGANIC_DELAY 2 SECONDS

/// How many organic items an organic processer can process at a time
#define SWARMER_ORGANIC_ITEM_PROCESS_LIMIT 5
/// How long does it take to process one organic item in organic processer
#define SWARMER_ORGANIC_ITEM_PROCESS_DELAY 10 SECONDS
/// How many organic resources we gain on item processing
#define SWARMER_ORGANIC_ITEM_PROCESS_GAIN (rand(2, 5))

/// How much time does it take for an organic analyzer to finish (non-carbon mobs take less time)
#define SWARMER_ANALYZE_DELAY(target) (iscarbon(target) ? 45 SECONDS : 15 SECONDS)

/// How many organic resources we get on teleporting if we failed the analyze
#define SWARMER_ANALYZE_TELEPORT_GAIN (rand(10, 20))
/// How many organic resources we get on analyzing a carbon mob
#define SWARMER_ANALYZE_CARBON_GAIN (rand(60, 80))
/// How many organic resources we get on analyzing a hostile mob (/mob/living/simple_animal/hostile)
#define SWARMER_ANALYZE_HOSTILE_GAIN (rand(20, 40))
/// How many organic resources we get on analyzing a living mob (/mob/living)
#define SWARMER_ANALYZE_LIVING_GAIN (rand(10, 20))
/// How many metallic resources we get on analyzing a carbon machine
#define SWARMER_ANALYZE_MACHINE_GAIN (rand(30, 50))
/// How many metallic resources we get on removing a robotic organ on analyzing
#define SWARMER_ANALYZE_ROBOTIC_ORGAN_GAIN 10

/// How many bodyparts or organs we take on machine analyze finish
#define SWARMER_ANALYZE_FINISH_MACHINE_TAKE 2
/// What is the chance to remove a bodypart or organ on non-machine analyze
#define SWARMER_ANALYZE_ORGAN_REMOVE_CHANCE 20

/// How long does it take to enter a repair station
#define SWARMER_REPAIR_STATION_DELAY 2 SECONDS
/// How much a swarmer gets healed by while being in a repair station per tick
#define SWARMER_REPAIR_STATION_HEAL 5

/// Metal gather modifier increase/decrease on storage init/destroy
#define SWARMER_STORAGE_MODIFIER 0.2
/// Metal gather modifier limit
#define SWARMER_STORAGE_MODIFIER_LIMIT 3

/// Rapid turret cooldown
#define SWARMER_RAPID_TURRET_COOLDOWN 1.5 SECONDS
/// Sniper turret cooldown
#define SWARMER_SNIPER_TURRET_COOLDOWN 2.5 SECONDS
/// ACP turret cooldown
#define SWARMER_ACP_TURRET_COOLDOWN 6 SECONDS

/// ACP turret stamina damage (gets scaled)
#define SWARMER_ACP_TURRET_DAMAGE 15
/// ACP turret range
#define SWARMER_ACP_TURRET_RANGE 3
/// ACP damage turret modifier on range decrease (as in less range from target -> more damage multiplier)
#define SWARMER_ACP_TURRET_RANGE_DAMAGE_MODIFIER 2
/// ACP turret slowed chance (gets scaled)
#define SWARMER_ACP_TURRET_SLOWED_CHANCE 60
/// ACP turret slowed duration (gets scaled up to 2x)
#define SWARMER_ACP_TURRET_SLOWED_DURATION 2 SECONDS
/// ACP turret slowed multiplier (doesn't scale)
#define SWARMER_ACP_TURRET_SLOWED_MULTIPLIER 2

/// For how long do swarmer structures get disabled for on emp_act
#define SWARMER_STRUCTURE_EMP_DURATION 10 SECONDS
