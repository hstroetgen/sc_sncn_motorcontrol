/**
 * @file user_config.h
 * @brief Motor Control config file (define your motor specifications here)
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <refclk.h>

#include <motor_config.h>

/////////////////////////////////////////////
//////  MOTOR SENSORS CONFIGURATION
/////////////////////////////////////////////
#include <sensor_config.h>
///////////////////////
// SENSOR 1 SETTINGS //
///////////////////////

// SENSOR 1 TYPE [HALL_SENSOR, REM_14_SENSOR, REM_16MT_SENSOR, BISS_SENSOR]
#define SENSOR_1_TYPE                     REM_16MT_SENSOR//HALL_SENSOR

// FUNCTION OF SENSOR_1 [ SENSOR_FUNCTION_DISABLED, SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL,
//                        SENSOR_FUNCTION_COMMUTATION_AND_FEEDBACK_ONLY,
//                        SENSOR_FUNCTION_MOTION_CONTROL, SENSOR_FUNCTION_FEEDBACK_ONLY]
// Only one sensor can be selected for commutation, motion control or feedback only
#define SENSOR_1_FUNCTION                 SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL

// RESOLUTION (TICKS PER TURN) OF SENSOR_1
#define SENSOR_1_RESOLUTION               REM_16MT_SENSOR_RESOLUTION

// VELOCITY COMPUTE PERIOD (ALSO POLLING RATE) OF SENSOR_1 (in microseconds)
#define SENSOR_1_VELOCITY_COMPUTE_PERIOD  REM_16MT_SENSOR_VELOCITY_COMPUTE_PERIOD

// POLARITY OF SENSOR_1 SENSOR [1,-1]
#define SENSOR_1_POLARITY                 NORMAL_POLARITY

///////////////////////
// SENSOR 2 SETTINGS //
///////////////////////

// SENSOR 2 TYPE [HALL_SENSOR, REM_14_SENSOR, REM_16MT_SENSOR, BISS_SENSOR]
#define SENSOR_2_TYPE                     HALL_SENSOR

// FUNCTION OF SENSOR_2 [ SENSOR_FUNCTION_DISABLED, SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL,
//                        SENSOR_FUNCTION_COMMUTATION_AND_FEEDBACK_ONLY,
//                        SENSOR_FUNCTION_MOTION_CONTROL, SENSOR_FUNCTION_FEEDBACK_ONLY]
// Only one sensor can be selected for commutation, motion control or feedback only
#define SENSOR_2_FUNCTION                 SENSOR_FUNCTION_DISABLED

// RESOLUTION (TICKS PER TURN) OF SENSOR_2
#define SENSOR_2_RESOLUTION               HALL_SENSOR_RESOLUTION

// VELOCITY COMPUTE PERIOD (ALSO POLLING RATE) OF SENSOR_2 (in microseconds)
#define SENSOR_2_VELOCITY_COMPUTE_PERIOD  HALL_SENSOR_VELOCITY_COMPUTE_PERIOD

// POLARITY OF SENSOR_2 SENSOR [1,-1]
#define SENSOR_2_POLARITY                 NORMAL_POLARITY


//////////////////////////////////////////////
//////  RECUPERATION MODE PARAMETERS
//////////////////////////////////////////////

/*
 * By default, RECUPERATION MODE is activated. Setting the maximum power of recuperation to a high
 * value (such as 10 times the nominal power) results in having no limit while working under recuperation mode.
 * In high-power applications (such as electric vehicles), this mode shoule
 * be activated only if dc-power supply is capable of accepting energy.
 * */

#define RECUPERATION        1          // when RECUPERATION is 0, there will be no recuperation

#define BATTERY_E_MAX       80         // maximum energy status of battery
#define BATTERY_E_MIN       10         // minimum energy status of battery

#define REGEN_P_MAX         50000      // maximum regenerative power (in Watts)
#define REGEN_P_MIN         0          // minimum regenerative power (in Watts)

#define REGEN_SPEED_MAX     650
#define REGEN_SPEED_MIN     50         // minimum value of the speed which is considered in regenerative calculations


//////////////////////////////////////////////
//////  PROTECTION CONFIGURATION
//////////////////////////////////////////////

#define I_MAX           100     //maximum tolerable value of phase current (under abnormal conditions)
#define V_DC_MAX        60      //maximum tolerable value of dc-bus voltage (under abnormal conditions)
#define V_DC_MIN        10      //minimum tolerable value of dc-bus voltave (under abnormal conditions)
#define TEMP_BOARD_MAX  100     //maximum tolerable value of board temperature (optional)


//////////////////////////////////////////////
//////  IFM TILE FREQ CONFIGURATION
//////////////////////////////////////////////

#define IFM_TILE_USEC   USEC_FAST // Number of ticks in a microsecond for IFM Tile

//////////////////////////////////////////////
//////  MOTOR COMMUTATION CONFIGURATION
//////////////////////////////////////////////
#define VDC             20

// COMMUTATION LOOP PERIOD (if applicable) [us]
#define COMMUTATION_LOOP_PERIOD     83
#define COMMUTATION_FRQ             24

//// COMMUTATION CW SPIN OFFSET (if applicable) [0:4095]
#define COMMUTATION_OFFSET_CLK      0

// (OPTIONAL) MOTOR ANGLE IN EACH HALL STATE. IN CASE HALL SENSOR IS USED FIND THE
// FOLLOWING VALUES BY RUNNING OFFSET DETECTION FUNCTION, OR SET THEM ALL TO 0
#define HALL_STATE_1_ANGLE     0
#define HALL_STATE_2_ANGLE     0
#define HALL_STATE_3_ANGLE     0
#define HALL_STATE_4_ANGLE     0
#define HALL_STATE_5_ANGLE     0
#define HALL_STATE_6_ANGLE     0

// MOTOR POLARITY [NORMAL_POLARITY, INVERTED_POLARITY]
#define MOTOR_POLARITY              NORMAL_POLARITY


///////////////////////////////////////////////
//////  MOTOR CONTROL CONFIGURATION
///////////////////////////////////////////////

// motor id (in case more than 1 motor is controlled)
#define MOTOR_ID 0

// PID FOR TORQUE CONTROL (if applicable) [will be divided by 10000]
#define TORQUE_Kp         40
#define TORQUE_Ki         40
#define TORQUE_Kd         0

// (maximum) generated torque while finding offset value as a percentage of rated torque
#define PERCENT_OFFSET_TORQUE 20


/////////////////////////////////////////////////
//////  PROFILES AND LIMITS CONFIGURATION
/////////////////////////////////////////////////

// POLARITY OF THE MOVEMENT OF YOUR MOTOR [1,-1]
#define POLARITY           1

// PROFILER LIMITS
#define MAX_ACCELERATION        7000            // rpm/s
#define MAX_DECELERATION        7000            // rpm/s


/////////////////////////////////////////////////
//////  POSITION CONTROLLER
/////////////////////////////////////////////////

//Limits
#define MIN_POSITION_LIMIT                     -0x7fffffff
#define MAX_POSITION_LIMIT                      0x7fffffff
#define TORQUE_CONTROL_LIMIT                    MAXIMUM_TORQUE

//Integrated Profiler
#define ENABLE_PROFILER                         0
#define MAX_ACCELERATION_PROFILER               1800000
#define MAX_SPEED_PROFILER                      1800000

/*
//PID parameters of the position PID controller
#define POSITION_Kp                             30000
#define POSITION_Ki                             10
#define POSITION_Kd                             0
#define POSITION_INTEGRAL_LIMIT                 400000 //in case of using non-linear position control,
                                                       //set "POSITION_INTEGRAL_LIMIT" to 1000
*/


//PID parameters of non-linear position controller. In case non-linear position controller is selected, these three
//constants "POSITION_Kp", "POSITION_Ki" and "POSITION_Kd" should be between 0 and 10^8. Inside the controller, these
//constants will be divided by 10^6. In other words, the precision in this mode will be 6 floating point digits.

/*
//-----  default values  -----
#define MAX_SPEED                               0    // prefered value 3000, maximum value 5000 [rpm]

#define POSITION_INTEGRAL_LIMIT                 1000 //in case of using non-linear position control,
                                                     //set "POSITION_INTEGRAL_LIMIT" to 1000

#define MOMENT_OF_INERTIA                       0    //set this variable only if it is known in [gram square centimiter]
                                                     //otherwise set as 0
*/

/*
//simple pid pos controller
#define POSITION_Kp                             50000
#define POSITION_Ki                             200
#define POSITION_Kd                             0
*/

/*
//cascade pos controller
#define POSITION_Kp                             0
#define POSITION_Ki                             0
#define POSITION_Kd                             0
*/


//nonlinear mode
#define POSITION_Kp                             20000
#define POSITION_Ki                             2000
#define POSITION_Kd                             80000


#define MAX_SPEED                               3000    // prefered value 3000, maximum value 5000 [rpm]

//in case of using non-linear position control set "POSITION_INTEGRAL_LIMIT" to 1000
#define POSITION_INTEGRAL_LIMIT                 1000

#define MOMENT_OF_INERTIA                       0    //set this variable only if it is known in [gram square centimiter]
                                                     //otherwise set as 0

//PID parameters of the velocity PID controller
#define VELOCITY_Kp                             700000
#define VELOCITY_Ki                             20000
#define VELOCITY_Kd                             0
#define VELOCITY_INTEGRAL_LIMIT                 MAXIMUM_TORQUE


//Filter parameters
#define POSITION_FC             100
#define VELOCITY_FC             90

//////////////////////////////////////////////
//////  BRAKE CONFIGURATION
//////////////////////////////////////////////
#define ENABLE_SHAKE_BRAKE     0

#define BRAKE_SHUTDOWN_DELAY   0     //delay in milliseconds between the brake blocking and the stop of the control

/*
 * Define: Voltage which will be applied to electric brake to release (pull) the brake at startup in [milli-Volt].
 * Note: The final voltage (on brake terminals) depends on brake loading characteristics. Generated voltage is precise in the case of pure resistive brake.
 */
#define VOLTAGE_PULL_BRAKE     13000    // [milli-Volts]

/*
 * Define: Voltage which will be applied to electric brake to hold the brake after it is pulled [milli-Volt].
 * Note: The final voltage (on brake terminals) depends on brake loading characteristics. Generated voltage is precise in the case of pure resistive brake.
 */
#define VOLTAGE_HOLD_BRAKE     7000     // [milli-Volts]

#define TIME_PULL_BRAKE        10000    //Time period in which it is tried to release (pull) the brake [milli seconds]


