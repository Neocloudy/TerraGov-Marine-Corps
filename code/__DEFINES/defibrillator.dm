///The base healing number for a defibrillator.
#define DEFIBRILLATOR_BASE_HEALING_VALUE 8

///How often you can defib someone
#define DEFIBRILLATOR_COOLDOWN 1 SECONDS

/**
 * A macro for healing with a defibrillator.
 *
 * * `skill_input` - What to multiply `healing_value` by.
 * * `healing_value` - The number to multiply. Should be [DEFIBRILLATOR_BASE_HEALING_VALUE] unless you want to change the base healing value
 */
#define DEFIBRILLATOR_HEALING_TIMES_SKILL(skill_input, healing_value) max(healing_value * skill_input * 0.5, 0)

///The base time for the initial progress bar when defibrillating somebody.
///Essentially: this + 3 seconds (from the second progress bar).
#define DEFIB_BASE_SETUP_SPEED (4 SECONDS)
///The multiplier for `DEFIB_SETUP_SPEED_TIMES_SKILL`.
#define DEFIB_SETUP_SPEED_FACTOR 0.8
///Macro for handling setup speed with a defibrillator.
#define DEFIB_SETUP_SPEED_TIMES_SKILL(medical_skill, setup_speed, average_skill) max(setup_speed * (1 - ((medical_skill - average_skill) / 3) * DEFIB_SETUP_SPEED_FACTOR), 0.15)
///Base charge cost with a defibrillator.
#define DEFIB_BASE_CHARGE_COST 66
///Minimum charge cost mult with a defibrillator.
#define DEFIB_CHARGE_COST_MINIMUM_MULT (DEFIB_BASE_CHARGE_COST * 0.01)
///Macro for handling charge cost based on skill.
#define DEFIB_CHARGE_COST_SKILL_MULT(medical_skill, average_skill) max((1 - ((medical_skill - average_skill) / 3)), DEFIB_CHARGE_COST_MINIMUM_MULT)

// Defibrillation outcomes, used in human_defines.dm
///Ready to defibrillate
#define DEFIB_POSSIBLE (1<<0)
///Missing a head
#define DEFIB_FAIL_DECAPITATED (1<<1)
///They have TRAIT_UNDEFIBBABLE
#define DEFIB_FAIL_BRAINDEAD (1<<2)
///Doesn't have the required organs to sustain life OR heart is broken
#define DEFIB_FAIL_BAD_ORGANS (1<<3)
///Too much damage
#define DEFIB_FAIL_TOO_MUCH_DAMAGE (1<<4)

///Revival states that strictly entail permadeath. These will prevent defibrillation
#define DEFIB_PREVENT_REVIVE_STATES (DEFIB_FAIL_DECAPITATED | DEFIB_FAIL_BRAINDEAD)
///All defibrillation outcomes that leave a revivable patient
#define DEFIB_REVIVABLE_STATES (DEFIB_FAIL_BAD_ORGANS | DEFIB_FAIL_TOO_MUCH_DAMAGE | DEFIB_POSSIBLE)
