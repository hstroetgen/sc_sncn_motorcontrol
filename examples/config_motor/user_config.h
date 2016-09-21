/**
 * @file user_config.h
 * @brief Motor Control config file (define your motor specifications here)
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once


//#include <motor_configs/motor_config_Nanotec_DB42C01.h>
//#include <motor_configs/motor_config_Nanotec_DB42C02.h>
//#include <motor_configs/motor_config_Nanotec_DB42C03.h>
//#include <motor_configs/motor_config_Nanotec_DB42L01.h>
//#include <motor_configs/motor_config_Nanotec_DB42M01.h>
//#include <motor_configs/motor_config_Nanotec_DB42M02.h>
//#include <motor_configs/motor_config_Nanotec_DB42M03.h>
//#include <motor_configs/motor_config_Nanotec_DB42S01.h>
//#include <motor_configs/motor_config_Nanotec_DB42S02.h>
//#include <motor_configs/motor_config_Nanotec_DB42S03.h>
//#include <motor_configs/motor_config_Nanotec_DB87S01.h>
//#include <motor_configs/motor_config_LDO_42BLS41.h>
//#include <motor_configs/motor_config_Moons_42BL30L2.h>
//#include <motor_config_Nanotec_DB59L024035-A.h>
//#include <motor_config_MABI_Hohlwellenservomotor_A5.h>
//#include <motor_config_MABI_A1.h>
//#include <motor_config_qmot_qbl5704.h>
//#include <motor_config_AMK_DT3.h>

#include <motor_config.h>

/////////////////////////////////////////////
//////  MOTOR SENSORS CONFIGURATION
/////////////////////////////////////////////

// SENSOR USED FOR COMMUTATION (if applicable) [HALL_SENSOR]
#define MOTOR_COMMUTATION_SENSOR   CONTELEC_SENSOR

// SENSOR USED FOR CONTROL FEEDBACK [HALL_SENSOR, QEI_SENSOR, BISS_SENSOR]
#define MOTOR_FEEDBACK_SENSOR      MOTOR_COMMUTATION_SENSOR

// TYPE OF INCREMENTAL ENCODER (if applicable) [QEI_WITH_INDEX, QEI_WITH_NO_INDEX]
#define QEI_SENSOR_INDEX_TYPE       QEI_WITH_INDEX

// TYPE OF SIGNAL FOR INCREMENTAL ENCODER (if applicable) [QEI_RS422_SIGNAL, QEI_TTL_SIGNAL]
#define QEI_SENSOR_SIGNAL_TYPE      QEI_RS422_SIGNAL

// RESOLUTION OF YOUR INCREMENTAL ENCODER (if applicable)
#define QEI_SENSOR_RESOLUTION       4000

// POLARITY OF YOUR INCREMENTAL ENCODER (if applicable) [1, -1]
#define QEI_SENSOR_POLARITY         1

// POLARITY OF YOUR HALL SENSOR (if applicable) [1,-1]
#define HALL_POLARITY              1


//////////////////////////////////////////////
//////  RECUPERATION MODE PARAMETERS
//////////////////////////////////////////////

/*
 * WARNING: explosion danger. This mode shoule not be activated before evaluating battery behaviour.
 * */

// For not affecting higher controlling levels (such as position control),
// RECUPERATION should be set to 1, and REGEN_P_MAX should be set to a much higher value than the rated power
// (such as 50 kW),

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

#define I_MAX           100      //maximum tolerable value of phase current (under abnormal conditions)
#define V_DC_MAX        60      //maximum tolerable value of dc-bus voltage (under abnormal conditions)
#define V_DC_MIN        10      //minimum tolerable value of dc-bus voltave (under abnormal conditions)
#define TEMP_BOARD_MAX  100     //maximum tolerable value of board temperature (optional)


//////////////////////////////////////////////
//////  BRAKE CONFIGURATION
//////////////////////////////////////////////
/*
//MABI PROJECT
#define DUTY_START_BRAKE    12000   // duty cycles for brake release (should be a number between 1500 and 13000)
#define DUTY_MAINTAIN_BRAKE 2000    // duty cycles for keeping the brake released (should be a number between 1500 and 13000)
*/

//FORESIGHT PROJECT
#define DUTY_START_BRAKE    10000   // duty cycles for brake release (should be a number between 1500 and 13000)
#define DUTY_MAINTAIN_BRAKE 1500    // duty cycles for keeping the brake released (should be a number between 1500 and 13000)

#define PERIOD_START_BRAKE  1000    // period in which high voltage is applied for realising the brake [milli-seconds]

//////////////////////////////////////////////
//////  MOTOR COMMUTATION CONFIGURATION
//////////////////////////////////////////////

#define VDC             48

// COMMUTATION LOOP PERIOD (if applicable) [us]
#define COMMUTATION_LOOP_PERIOD     66

// COMMUTATION CW SPIN OFFSET (if applicable) [0:4095]
#define COMMUTATION_OFFSET_CLK      2400//590

// MOTOR ANGLE IN EACH HALL STATE (should be configured in case HALL sensor is used)
#define HALL_STATE_1_ANGLE     0
#define HALL_STATE_2_ANGLE     0
#define HALL_STATE_3_ANGLE     0
#define HALL_STATE_4_ANGLE     0
#define HALL_STATE_5_ANGLE     0
#define HALL_STATE_6_ANGLE     0

// COMMUTATION CCW SPIN OFFSET (if applicable) [0:4095]
#define COMMUTATION_OFFSET_CCLK     0

// MOTOR POLARITY [NORMAL_POLARITY, INVERTED_POLARITY]
#define MOTOR_POLARITY              NORMAL_POLARITY


///////////////////////////////////////////////
//////  MOTOR CONTROL CONFIGURATION
///////////////////////////////////////////////

// POSITION CONTROL LOOP PERIOD [us]
#define CONTROL_LOOP_PERIOD     1000 //500

// PID FOR POSITION CONTROL (if applicable) [will be divided by 10000]
//#define POSITION_Kp       100
//#define POSITION_Ki       1
//#define POSITION_Kd       0

// PID FOR VELOCITY CONTROL (if applicable) [will be divided by 10000]
//#define VELOCITY_Kp       667
//#define VELOCITY_Ki       200
//#define VELOCITY_Kd       0

// PID FOR TORQUE CONTROL (if applicable) [will be divided by 10000]
#define TORQUE_Kp         40 //7
#define TORQUE_Ki         40  //3
#define TORQUE_Kd         0

// (maximum) generated torque while finding offset value as a percentage of rated torque
#define PERCENT_OFFSET_TORQUE 80


/////////////////////////////////////////////////
//////  PROFILES AND LIMITS CONFIGURATION
/////////////////////////////////////////////////

// POLARITY OF THE MOVEMENT OF YOUR MOTOR [1,-1]
#define POLARITY           1

// DEFAULT PROFILER SETTINGS FOR PROFILE ETHERCAT DRIVE
#define PROFILE_VELOCITY        1000        // rpm
#define PROFILE_ACCELERATION    2000        // rpm/s
#define PROFILE_DECELERATION    2000        // rpm/s
#define PROFILE_TORQUE_SLOPE    400         // adc_ticks

// PROFILER LIMITIS
//#define MAX_POSITION_LIMIT      0x7fffffff        // ticks (max range: 2^30, limited for safe operation)
//#define MIN_POSITION_LIMIT     -0x7fffffff        // ticks (min range: -2^30, limited for safe operation)
//#define MAX_VELOCITY            7000              // rpm
#define MAX_ACCELERATION        7000            // rpm/s
#define MAX_DECELERATION        7000            // rpm/s
#define MAX_CURRENT_VARIATION   800             // adc_ticks/s
#define MAX_CURRENT             800             // adc_ticks



/////////////////////////////////////////////////
//////  POSITION CONTROLLER
/////////////////////////////////////////////////
//**Foresight Joint 3
#define MIN_POSITION_LIMIT                     -300000
#define MAX_POSITION_LIMIT                      300000
#define MAX_VELOCITY                            1500 //rpm
#define MAX_TORQUE                              3000

#define ENABLE_PROFILER                         1
#define MAX_ACCELERATION_PROFILER               1800000
#define MAX_SPEED_PROFILER                      1800000

//PID parameters of the position PID controller
#define Kp_POS_PID                              30000
#define Ki_POS_PID                              10
#define Kd_POS_PID                              0
#define INTEGRAL_LIMIT_POS_PID                  400000

//PID parameters of the velocity PID controller
#define Kp_VELOCITY_PID                         100
#define Ki_VELOCITY_PID                         0
#define Kd_VELOCITY_PID                         60
#define INTEGRAL_LIMIT_VELOCITY_PID             0

//PID parameters of the Integral Optimum position controller
#define Kp_POS_INTEGRAL_OPTIMUM                 1000
#define Ki_POS_INTEGRAL_OPTIMUM                 1000
#define Kd_POS_INTEGRAL_OPTIMUM                 1000

//PID parameters of the Integral Optimum position controller
#define Kp_NL_POS_CONTROL                   989500
#define Ki_NL_POS_CONTROL                   100100
#define Kd_NL_POS_CONTROL                   4142100

#define INTEGRAL_LIMIT_POS_INTEGRAL_OPTIMUM     1500000

#define POSITION_FC             100
#define VELOCITY_FC             90

#define K_FB                   10429000
#define K_M                    1

#define MOMENT_OF_INERTIA      100 //[micro-kgm2]

#define GAIN_P      1000
#define GAIN_I      1000
#define GAIN_D      1000




