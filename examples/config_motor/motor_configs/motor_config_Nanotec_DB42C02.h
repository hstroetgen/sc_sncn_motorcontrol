/**
 * @file motor_config_Nanotec_DB42C02.h
 * @brief Motor Control config file (define your motor specifications here)
 * @author Synapticon GmbH <support@synapticon.com>
 */

/**************************************************
 *********      USER CONFIGURATION       **********
 **************************************************/

/////////////////////////////////////////////
//////  GENERAL MOTOR CONFIGURATION
////////////////////////////////////////////


// IMPORTANT PARAMETERS (=> lead to mulfunction or damage if set wrong)
#define MOTOR_POLE_PAIRS        4      //number of motor pole-pairs
#define MOTOR_TORQUE_CONSTANT   30000  //Torque constant [micro-Nm/Amp-RMS]
#define MOTOR_RATED_CURRENT           3570   //rated phase current [milli-Amp-RMS]
#define MOTOR_MAXIMUM_TORQUE          300    //maximum value of torque which can be produced by motor [milli-Nm]
#define MOTOR_RATED_TORQUE            100    //rated motor torque [milli-Nm].

// OTHER PARAMETERS (do not change if not having access to the following parameter values)
#define RATED_POWER             147     // rated power [W]
#define PEAK_SPEED              14000   // maximum motor speed [rpm]
#define MOTOR_PHASE_RESISTANCE  200000  // motor phase resistance [micro-ohm]
#define MOTOR_PHASE_INDUCTANCE  320     // motor phase inductance [micro-Henry]

// GENERAL PARAMETERS
#define MOTOR_TYPE              BLDC_MOTOR      //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
