/*
 * motor_control_structures.h
 *
 *  Created on: Aug 2, 2016
 *      Author: ramin
 */


#ifndef MOTOR_CONTROL_STRUCTURES_H_
#define MOTOR_CONTROL_STRUCTURES_H_

/**
 * @brief Status of motor control related task
 * ACTIVE   -> the task is started and can be used as a server
 * INACTIVE -> the task is not started yet
 */
typedef enum {
    INACTIVE= 1,
    ACTIVE = 2
} TaskStatus;


/**
 * @brief Type for position sensors.
 */
typedef enum {
    HALL_SENSOR= 1,
    QEI_SENSOR = 2,
    BISS_SENSOR= 4,
    REM_16MT_SENSOR=6
} SensorType;

/**
 * @brief Type for motors.
 */
typedef enum {
    BDC_MOTOR  = 10, /**< Brushed DC Motor. */
    BLDC_MOTOR = 11  /**< Brush-less DC Motor. */
} MotorType;

/**
 * @brief Commutation method.
 */
typedef enum {
    SINE = 20,  /**< Sine commutation. */
    FOC  = 21  /**< Vector control. */
} CommutationMethod;

/**
 * @brief Type for the kind of winding of a BLDC motor.
 */
typedef enum {
    STAR_WINDING=1, /**< Star winding. */
    DELTA_WINDING   /**< Delta winding. */
} BLDCWindingType;

/**
 * @brief Type for the polarity of a motor.
 */
typedef enum {
    NORMAL_POLARITY  = 1, /**< Normal polarity. */
    INVERTED_POLARITY=-1   /**< Inverted polarity. */
} PolarityType;

/**
 * @brief Fault Codes
 */
typedef enum {
    NO_FAULT=0,
    OVER_CURRENT_PHASE_A = 1,
    OVER_CURRENT_PHASE_B = 2,
    OVER_CURRENT_PHASE_C = 3,
    UNDER_VOLTAGE = 4,
    OVER_VOLTAGE = 5,
    WRONG_LICENCE=6,
    WRONG_REF_CLK_FRQ=7
} FaultCode;

/**
 * Structure type for Motorcontrol Service configuration.
 */
typedef struct {
    MotorType motor_type;                   /**< Type of motor to drive. */
    CommutationMethod commutation_method;   /**< Commutation method. */
    BLDCWindingType bldc_winding_type;      /**< Type of winding of your motor (if using a BLDC motor). */
    PolarityType polarity_type;             /**< Type of polarity of your motor. */
    int licence;                            /**< Licence number for using the library of module_advanced_foc  */
    int commutation_sensor;                 /**< Absolute position sensor used for commutation (if using a BLDC motor). For the moment just Hall sensor can be used [HALL_SENSOR]. */
    int hall_offset[2];                     /**< Feedback Hall sensor error offset for positive (hall_offset[0]) and negative (hall_offset[1]) turning [0:4095]. (Often required to optimize commutation if using a BLDC motor). */
    int hall_state_1;                       /**< Hall port state while being in sector 1*/
    int hall_state_2;                       /**< Hall port state while being in sector 2*/
    int hall_state_3;                       /**< Hall port state while being in sector 3*/
    int hall_state_4;                       /**< Hall port state while being in sector 4*/
    int hall_state_5;                       /**< Hall port state while being in sector 5*/
    int hall_state_6;                       /**< Hall port state while being in sector 6*/

    int hall_state_1_angle;                 /**< estimated angle while being in sector 1*/
    int hall_state_2_angle;                 /**< estimated angle while being in sector 2*/
    int hall_state_3_angle;                 /**< estimated angle while being in sector 3*/
    int hall_state_4_angle;                 /**< estimated angle while being in sector 4*/
    int hall_state_5_angle;                 /**< estimated angle while being in sector 5*/
    int hall_state_6_angle;                 /**< estimated angle while being in sector 6*/

    int commutation_loop_period;            /**< Period for the commutation loop [microseconds]. */

    //variables added to be used in motor_control_service
    int pole_pair;                          /**< motor pole pair*/
    int max_torque;                         /**< maximum motor torque*/
    int max_current;                        /**< maximum stator current*/
    int rated_current;                      /**< rated motor phase current*/
    int rated_torque;                       /**< rated motor torque*/
    int commutation_angle_offset;           /**< position offset (which is finally added to the value which is recived from position sensor to compensate the required angle shift)*/
    int torque_constant;                    /**< motor torque constant*/
    int current_P_gain;                     /**< proportional constant in torque controller*/
    int current_I_gain;                     /**< integral constant in torque controller*/
    int current_D_gain;                     /**< derivative constant in torque controller*/
    int current_ratio;                      //ratio between current recieved in control core, and real phase current
    int percent_offset_torque;              // (maximum) generated torque while finding offset value as a percentage of rated torque

    int phase_resistance;                   /**< uOhm*/
    int phase_inductance;                   /**< uH*/
    int v_dc;                               /**< dc bus voltage*/

    // regenerative mode variables
    int recuperation;

    int battery_e_max;  // maximum energy status of battery
    int battery_e_min;  // minimum energy status of battery
    int regen_p_max;    // maximum regenerative power (in Watts)
    int regen_p_min;    // minimum regenerative power (in Watts)
    int regen_speed_max;
    int regen_speed_min;

    // protection limits
    // comment: there are some definitions in standard dictionary (such as MAX_TORQUE, MAX_CURRENT, ...) but
    //          these values are for normal operation. (with high probability) the protection limits are different
    //          than these maximum values...
    int protection_limit_over_current;  //maximum tolerable value of phase current (under abnormal conditions)
    int protection_limit_over_voltage;  //maximum tolerable value of dc-bus voltage (under abnormal conditions)
    int protection_limit_under_voltage; //minimum tolerable value of dc-bus voltave (under abnormal conditions)

} MotorcontrolConfig;


/**
 * @brief Structure type to send the data from lower controlling levels
 * to higher controlling levels
 */
typedef struct
{
    int error_status;

    int computed_torque;
    int torque_set;

    int sensor_torque;

    int V_dc;

    int angle;
    int position;
    int velocity;

    int temperature;

}UpstreamControlData;

/**
 * @brief Structure type to send the data from higher controlling levels
 * to higher controlling levels
 */
typedef struct
{
    int position_cmd;
    int velocity_cmd;
    int torque_cmd;
    int offset_torque;
}DownstreamControlData;


#endif /* MOTOR_CONTROL_STRUCTURES_H_ */
