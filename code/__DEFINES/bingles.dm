/// Lazy assoc list in format Key(hole UID) - List(mobs)
GLOBAL_LIST_EMPTY(bingles_by_hole)

/// Max pit size of bingle hole (Also the goal of bingles)
#define BINGLE_PIT_SIZE_GOAL 50
/// At what size do we announce to the station about bingles
#define ANNOUNCE_BINGLE_PIT_SIZE 3
/// At what size do we send nuclear codes
#define NUCLEAR_CODE_BINGLE_PIT_SIZE 25

/// How much time is given at BINGLE_PIT_SIZE_GOAL for crew to kill the hole until it wins
#define BINGLE_PIT_WIN_DELAY 2 MINUTES

/// By how much do we multiply maxHealth variable on evolve
#define BINGLE_EVOLVE_HEALTH_MULTIPLIER 1.5
/// By how much do we multiply obj_damage variable on evolve
#define BINGLE_EVOLVE_OBJ_DAMAGE_MULTIPLIER 2

/// By how much do we increase the health of the bingle pit on growth
#define BINGLE_PIT_GROW_INTEGRITY_INCREASE 25
/// How often based on item_value_consumed do we grow the pit
#define BINGLE_PIT_GROW_VALUE 100
/// How often based on item_value_consumed do we spawn a bingle
#define BINGLE_SPAWN_VALUE 50
/// At what item_value_consumed do bingles become evolved
#define BINGLE_EVOLVE_VALUE 500
/// How much does the pit gain from living mobs
#define BINGLE_PIT_LIVING_VALUE 25
/// How much the pit should heal from BINGLE_PIT_LIVING_VALUE multiplied by this
#define BINGLE_PIT_LIVING_HEAL_MULTIPLIER 1.5
/// Limit of value gained from stack items
#define BINGLE_PIT_STACK_GAIN_LIMIT 50
