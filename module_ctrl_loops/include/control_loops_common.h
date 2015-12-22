/**
 * @file control_loops_common.h
 * @brief Common declarations for control loops
 */

#pragma once

#define PID_DENOMINATOR 10000.0

/**
 * @brief Struct definition for PID Controller
 */
typedef struct {
    int Kp; /**< Kp = Kp_n/Kp_d */
    int Ki; /**< Ki = Ki_n/Ki_d */
    int Kd; /**< Kd = Kd_n/Kd_d */
    int control_loop_period;
    int feedback_sensor;
} ControlConfig;


/**
 * @brief Struct definition for profile velocity param
 */
typedef struct{
    int polarity;

    //Position
    int velocity;
    int max_position;
    int min_position;

    //Velocity
    int acceleration;
    int deceleration;
    int max_acceleration;
    int max_deceleration;
    int max_velocity;

    //Torque
    int current_slope;   //not used for now
    int max_current_slope;
    int max_current;
}ProfilerConfig;

/**
 * @brief Struct definition for Synchronous torque param
 */
typedef struct
{
    int nominal_motor_speed;
    int nominal_current;
    int motor_torque_constant;
    int max_torque;
    int polarity;
} CyclicSyncTorqueConfig;

/**
 * @brief Struct definition for Synchronous velocity param
 */
typedef struct
{
    int max_motor_speed;
    int nominal_current;
    int motor_torque_constant;
    int polarity;
    int max_acceleration;
} CyclicSyncVelocityConfig;

/**
 * @brief Struct definition for Synchronous position param
 */
typedef struct
{
    CyclicSyncVelocityConfig velocity_config;
    int max_following_error;
    int max_position_limit;
    int min_position_limit;
} CyclicSyncPositionConfig;
