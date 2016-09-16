/**
 * @file motor_config.h
 * @brief Motor Control config file (define your motor specifications here)
 * @author Synapticon GmbH <support@synapticon.com>
 *
 *   Example motor config file
 */

/**************************************************
 *********      USER CONFIGURATION       **********
 **************************************************/

#define POWER_FACTOR           0

/////////////////////////////////////////////
//////  MOTOR PARAMETERS
////////////////////////////////////////////

// uncomment, and complete the following part depending on your motor model.
// There are some examples in the following...

/*
// motor model:

// IMPORTANT PARAMETERS (=> lead to mulfunction or damage if set wrong)
#define POLE_PAIRS                      //number of motor pole-pairs
#define PERCENT_TORQUE_CONSTANT         //motor torque constant multiplied by 100
#define RATED_CURRENT                   //rated phase current [milli-Amp-RMS]
#define MAXIMUM_TORQUE                  //maximum value of torque which can be produced by motor [milli-Nm]
#define RATED_TORQUE                    // rated motor torque [milli-Nm]

// OTHER PARAMETERS (do not change if not having access to the following parameter values)
#define RATED_POWER                     // rated power [W]
#define PEAK_SPEED                      // maximum motor speed [rpm]
#define PHASE_RESISTANCE                // motor phase resistance [micro-ohm]
#define PHASE_INDUCTANCE                // motor phase inductance [micro-Hunnry]

// GENERAL PARAMETERS
#define MOTOR_TYPE              BLDC_MOTOR      //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
#define BLDC_WINDING_TYPE       STAR_WINDING    //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
*/

/*
// chinese black motore
// IMPORTANT PARAMETERS (=> lead to mulfunction or damage if set wrong)
#define POLE_PAIRS              4       //number of motor pole-pairs
#define PERCENT_TORQUE_CONSTANT 13      //motor torque constant multiplied by 100
#define RATED_CURRENT           20000   //rated phase current [milli-Amp-RMS]
#define MAXIMUM_TORQUE          30000   //maximum value of torque which can be produced by motor [milli-Nm]
#define RATED_TORQUE            5000    //rated motor torque [milli-Nm]. CAUTION: CAN DAMAGE THE MOTOR OR INVERTER IF SET TOO HIGH

// OTHER PARAMETERS (do not change if not having access to the following parameter values)
#define RATED_POWER             4000   // rated power [W]
#define PEAK_SPEED              5000   // maximum motor speed [rpm]
#define PHASE_RESISTANCE        6200   // motor phase resistance [micro-ohm]
#define PHASE_INDUCTANCE          68   // motor phase inductance [micro-Hunnry]

// GENERAL PARAMETERS
#define MOTOR_TYPE              BLDC_MOTOR      //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
#define BLDC_WINDING_TYPE       STAR_WINDING    //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
*/

/*
// FAULHABER motor (150W)
// IMPORTANT PARAMETERS (=> lead to mulfunction or damage if set wrong)
#define POLE_PAIRS              2       //number of motor pole-pairs
#define PERCENT_TORQUE_CONSTANT 3      //motor torque constant multiplied by 100
#define RATED_CURRENT           4800   //rated phase current [milli-Amp-RMS]
#define MAXIMUM_TORQUE          330   //maximum value of torque which can be produced by motor [milli-Nm]
#define RATED_TORQUE            111    //rated motor torque [milli-Nm]. CAUTION: CAN DAMAGE THE MOTOR OR INVERTER IF SET TOO HIGH

// OTHER PARAMETERS (do not change if not having access to the following parameter values)
#define RATED_POWER             150   // rated power [W]
#define PEAK_SPEED              16000   // maximum motor speed [rpm]
#define PHASE_RESISTANCE        250000   // motor phase resistance [micro-ohm]
#define PHASE_INDUCTANCE        60   // motor phase inductance [micro-Hunnry]

// GENERAL PARAMETERS
#define MOTOR_TYPE              BLDC_MOTOR      //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
#define BLDC_WINDING_TYPE       STAR_WINDING    //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
*/


// motor model: DT4

// IMPORTANT PARAMETERS (=> lead to mulfunction or damage if set wrong)
#define POLE_PAIRS              5       //number of motor pole-pairs
#define PERCENT_TORQUE_CONSTANT 15      //motor torque constant multiplied by 100
#define RATED_CURRENT           8000    //rated phase current [milli-Amp-RMS]
#define MAXIMUM_TORQUE          2500    //maximum value of torque which can be produced by motor [milli-Nm]
#define RATED_TORQUE            1250    //rated motor torque [milli-Nm].

// OTHER PARAMETERS (do not change if not having access to the following parameter values)
#define RATED_POWER             300     // rated power [W]
#define PEAK_SPEED              3700    // maximum motor speed [rpm]
#define PHASE_RESISTANCE        490000  // motor phase resistance [micro-ohm]
#define PHASE_INDUCTANCE        580     // motor phase inductance [micro-Hunnry]

// GENERAL PARAMETERS
#define MOTOR_TYPE              BLDC_MOTOR      //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]

/*
// 411678 MAXON motor

// IMPORTANT PARAMETERS (=> lead to mulfunction or damage if set wrong)
#define POLE_PAIRS              7         //number of motor pole-pairs
#define PERCENT_TORQUE_CONSTANT 5         //motor torque constant multiplied by 100
#define RATED_CURRENT           5470      //rated phase current [milli-Amp-RMS]
#define MAXIMUM_TORQUE          28900     //maximum value of torque which can be produced by motor [milli-Nm]
#define RATED_TORQUE            289       // rated motor torque [milli-Nm]

// OTHER PARAMETERS (do not change if not having access to the following parameter values)
#define RATED_POWER          100        // rated power [W]
#define PEAK_SPEED          4000        // maximum motor speed [rpm]
#define PHASE_RESISTANCE    152000      // motor phase resistance [micro-ohm]
#define PHASE_INDUCTANCE    188000      // motor phase inductance [micro-Hunnry]

// GENERAL PARAMETERS
#define MOTOR_TYPE              BLDC_MOTOR      //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
#define BLDC_WINDING_TYPE       STAR_WINDING    //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
*/

/*
// motor model: MABI AXIS_1 and AXIS_2

// IMPORTANT PARAMETERS (=> lead to mulfunction or damage if set wrong)
#define POLE_PAIRS              ?       //number of motor pole-pairs
#define PERCENT_TORQUE_CONSTANT         //motor torque constant multiplied by 100
#define RATED_CURRENT           20000   //rated phase current [milli-Amp-RMS]
#define MAXIMUM_TORQUE          ?       //maximum value of torque which can be produced by motor [milli-Nm]
#define RATED_TORQUE            540     // rated motor torque [milli-Nm]

// OTHER PARAMETERS (do not change if not having access to the following parameter values)
#define RATED_POWER             735     // rated power [W]
#define PEAK_SPEED              3000    // maximum motor speed [rpm]
#define PHASE_RESISTANCE        125000  // motor phase resistance [micro-ohm]
#define PHASE_INDUCTANCE        525     // motor phase inductance [micro-Hunnry]

// GENERAL PARAMETERS
#define MOTOR_TYPE              BLDC_MOTOR      //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
#define BLDC_WINDING_TYPE       STAR_WINDING    //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
*/

/*
// motor model: MABI AXIS_3 and AXIS_4

// IMPORTANT PARAMETERS (=> lead to mulfunction or damage if set wrong)
#define POLE_PAIRS              ?       //number of motor pole-pairs
#define PERCENT_TORQUE_CONSTANT ?       //motor torque constant multiplied by 100
#define RATED_CURRENT           11000   //rated phase current [milli-Amp-RMS]
#define MAXIMUM_TORQUE          ?       //maximum value of torque which can be produced by motor [milli-Nm]
#define RATED_TORQUE            143     // rated motor torque [milli-Nm]

// OTHER PARAMETERS (do not change if not having access to the following parameter values)
#define RATED_POWER             450     // rated power [W]
#define PEAK_SPEED              5000    // maximum motor speed [rpm]
#define PHASE_RESISTANCE        210000  // motor phase resistance [micro-ohm]
#define PHASE_INDUCTANCE        470     // motor phase inductance [micro-Hunnry]

// GENERAL PARAMETERS
#define MOTOR_TYPE              BLDC_MOTOR      //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
#define BLDC_WINDING_TYPE       STAR_WINDING    //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
*/

/*
// motor model: MABI AXIS_5 and AXIS_6

// IMPORTANT PARAMETERS (=> lead to mulfunction or damage if set wrong)
#define POLE_PAIRS              ?       //number of motor pole-pairs
#define PERCENT_TORQUE_CONSTANT ?       //motor torque constant multiplied by 100
#define RATED_CURRENT           5000    //rated phase current [milli-Amp-RMS]
#define MAXIMUM_TORQUE          ?       //maximum value of torque which can be produced by motor [milli-Nm]
#define RATED_TORQUE            270     // rated motor torque [milli-Nm]

// OTHER PARAMETERS (do not change if not having access to the following parameter values)
#define RATED_POWER             140     // rated power [W]
#define PEAK_SPEED              9000    // maximum motor speed [rpm]
#define PHASE_RESISTANCE        552000  // motor phase resistance [micro-ohm]
#define PHASE_INDUCTANCE        720     // motor phase inductance [micro-Hunnry]

// GENERAL PARAMETERS
#define MOTOR_TYPE              BLDC_MOTOR      //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
#define BLDC_WINDING_TYPE       STAR_WINDING    //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
*/



