/**
 * @file motor_config_Nanotec_DB59L024035-A.h
 * @brief Motor Control config file (define your motor specifications here)
 * @author Synapticon GmbH <support@synapticon.com>
 */

// IMPORTANT PARAMETERS (=> lead to mulfunction or damage if set wrong)
#define MOTOR_POLE_PAIRS        3       //number of motor pole-pairs
#define MOTOR_TORQUE_CONSTANT   50000  //Torque constant [micro-Nm/Amp-RMS]
#define MOTOR_RATED_CURRENT           9400    //rated phase current [milli-Amp-RMS]
#define MOTOR_MAXIMUM_TORQUE          1410    //maximum value of torque which can be produced by motor [milli-Nm]
#define MOTOR_RATED_TORQUE            470     // rated motor torque [milli-Nm]
#define MOTOR_MAX_SPEED               3000    // please update from the motor datasheet [rpm]

// OTHER PARAMETERS (do not change if not having access to the following parameter values)
#define RATED_POWER             172     // rated power [W]
#define PEAK_SPEED              4500    // maximum motor speed [rpm]
#define MOTOR_PHASE_RESISTANCE  220000  // motor phase resistance [micro-ohm]
#define MOTOR_PHASE_INDUCTANCE  290     // motor phase inductance [micro-Henry]

// GENERAL PARAMETERS
#define MOTOR_TYPE              BLDC_MOTOR      //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
