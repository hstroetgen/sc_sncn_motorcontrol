/**
 * @file controllers_lib.h
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once


/**
 * @brief Structure type to set the parameters of the PID controller.
 */
typedef struct {
    float Kp;
    float Ki;
    float Kd;
    float integral_limit;
    float integral;
    float actual_value_1n;
    int T_s;    //Sampling-Time in microseconds
} PIDparam;


/**
 * @brief Structure type to set the parameters of the integral optimum position controller.
 */
typedef struct {
    float Kp;
    float Ki;
    float Kd;
    float integral_limit;
    float integral;
    float actual_value_1n;
    int T_s;    //Sampling-Time in microseconds
} integralOptimumPosControllerParam;


/**
 * @brief Structure type to set the parameters of position reference profiler.
 */
typedef struct {
    float delta_T;
    float a_max;
    float v_max;
} posProfilerParam;




/**
 * @brief intializing the parameters of the PID controller.
 * @param the parameters of the controller
 */
void pid_init(PIDparam &param);


/**
 * @brief setting the parameters of the PID controller.
 * @param input, P parameter
 * @param input, I parameter
 * @param input, D parameter
 * @param input, Integral limit
 * @param input, sample-time in us (microseconds).
 * @param the parameters of the PID controller
 */
void pid_set_parameters(float Kp, float Ki, float Kd, float integral_limit, int T_s, PIDparam &param);


/**
 * @brief updating the PID controller.
 * @param output, control command
 * @param input, setpoint
 * @param input, feedback
 * @param input, sample-time in us (microseconds).
 * @param the parameters of the PID controller
 */
float pid_update(float desired_value, float actual_value, int T_s, PIDparam &param);


/**
 * @brief resetting the parameters of the PID controller.
 * @param the parameters of the controller
 */
void pid_reset(PIDparam &param);



/**
 * @brief intializing the parameters of the integral optimum position controller.
 * @param the parameters of the controller
 */
void integral_optimum_pos_controller_init(integralOptimumPosControllerParam &param);


/**
 * @brief setting the parameters of the integral optimum position controller.
 * @param input, P parameter
 * @param input, I parameter
 * @param input, D parameter
 * @param input, Integral limit
 * @param input, sample-time in us (microseconds).
 * @param the parameters of the integral optimum position controller
 */
void integral_optimum_pos_controller_set_parameters(float Kp, float Ki, float Kd, float integral_limit, int T_s, integralOptimumPosControllerParam &param);


/**
 * @brief updating the integral optimum position controller.
 * @param output, control command
 * @param input, setpoint
 * @param input, feedback
 * @param input, sample-time in us (microseconds).
 * @param the parameters of the integral optimum position controller
 */
float integral_optimum_pos_controller_updat(float desired_value, float actual_value, int T_s, integralOptimumPosControllerParam &param);


/**
 * @brief resetting the parameters of the integral optimum position controller.
 * @param the parameters of the controller
 */
void integral_optimum_pos_controller_reset(integralOptimumPosControllerParam &param);



/**
 * @brief updating the position reference profiler
 * @param output, profiled position calculated for the next step
 * @param input, target position
 * @param input, profiled position calculated in one step ago
 * @param input, profiled position calculated in two steps ago
 * @param the parameters of the position reference profiler
 */
float pos_profiler(float pos_target, float pos_k_1n, float pos_k_2n, posProfilerParam pos_profiler_param);







