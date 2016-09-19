/**
 * @file controllers_lib.xc
 * @brief Controllers Libraries
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <controllers_lib.h>
#include <control_loops_common.h>


/**
 * @brief sign function.
 * @param output, sign of the number
 * @param input, number
 */
int sign_function(float a)
{
    if (a < 0)
        return -1;
    else
        return 1;
}


/**
 * @brief intializing the parameters of the PID controller.
 * @param the parameters of the controller
 */
void pid_init(PIDparam &param)
{
    param.Kp = 0;
    param.Ki = 0;
    param.Kd = 0;
    param.integral_limit = 0;
    param.integral = 0;
    param.actual_value_1n = 0;
    param.T_s = 0;
}

/**
 * @brief setting the parameters of the PID controller.
 * @param input, P parameter
 * @param input, I parameter
 * @param input, D parameter
 * @param input, Integral limit
 * @param input, sample-time in us (microseconds).
 * @param the parameters of the PID controller
 */
void pid_set_parameters(float Kp, float Ki, float Kd, float integral_limit, int T_s, PIDparam &param)
{
    param.Kp = Kp;
    param.Ki = Ki;
    param.Kd = Kd;
    param.integral_limit = integral_limit;
    param.T_s = T_s;
}

/**
 * @brief updating the PID controller.
 * @param output, control command
 * @param input, setpoint
 * @param input, feedback
 * @param input, sample-time in us (microseconds).
 * @param the parameters of the PID controller
 */
float pid_update(float desired_value, float actual_value, int T_s, PIDparam &param)
{
    float error, cmd, integral_term;
    error = desired_value - actual_value;
    param.integral += error;
    integral_term = param.Ki * param.integral;
    if ((integral_term > param.integral_limit) || (integral_term < -param.integral_limit))
        param.integral -= error;
    cmd = ((param.Kp * error) + integral_term - (param.Kd * (actual_value - param.actual_value_1n)));
    param.actual_value_1n = actual_value;
    return cmd;
}


/**
 * @brief resetting the parameters of the PID controller.
 * @param the parameters of the controller
 */
void pid_reset(PIDparam &param)
{
    param.actual_value_1n = 0;
    param.integral = 0;
}


/**
 * @brief intializing the parameters of the integral optimum position controller.
 * @param the parameters of the controller
 */
void integral_optimum_pos_controller_init(integralOptimumPosControllerParam &param)
{
    param.Kp = 0;
    param.Ki = 0;
    param.Kd = 0;
    param.integral_limit = 0;
    param.integral = 0;
    param.actual_value_1n = 0;
    param.T_s = 0;
}

/**
 * @brief setting the parameters of the integral optimum position controller.
 * @param input, P parameter
 * @param input, I parameter
 * @param input, D parameter
 * @param input, Integral limit
 * @param input, sample-time in us (microseconds).
 * @param the parameters of the integral optimum position controller
 */
void integral_optimum_pos_controller_set_parameters(float Kp, float Ki, float Kd, float integral_limit, int T_s, integralOptimumPosControllerParam &param)
{
    param.Kp = Kp;
    param.Ki = Ki;
    param.Kd = Kd;
    param.integral_limit = integral_limit;
    param.T_s = T_s;
}


/**
 * @brief updating the integral optimum position controller.
 * @param output, control command
 * @param input, setpoint
 * @param input, feedback
 * @param input, sample-time in us (microseconds).
 * @param the parameters of the integral optimum position controller
 */
float integral_optimum_pos_controller_updat(float desired_value, float actual_value, int T_s, integralOptimumPosControllerParam &param)
{
    float cmd, temp;
    temp = param.integral;
    param.integral += ((desired_value * param.Ki) - (actual_value * (param.Ki + param.Kp)) + (param.actual_value_1n * param.Kp));
    if((param.integral > param.integral_limit) || (param.integral < -param.integral_limit))
        param.integral = temp;
    cmd = param.integral - (actual_value * param.Kd) + (param.actual_value_1n * param.Kd);
    param.actual_value_1n = actual_value;
    return cmd;
}


/**
 * @brief resetting the parameters of the integral optimum position controller.
 * @param the parameters of the controller
 */
void integral_optimum_pos_controller_reset(integralOptimumPosControllerParam &param)
{
    param.actual_value_1n = 0;
    param.integral = 0;
}

void position_control_with_saturation_reset(PositionControlWithSaturation &pos_ctrl_with_saturation)
{
    //************************************************
    // reset position controller structure
    pos_ctrl_with_saturation.j = 0.00; // in micro-kgm2
    pos_ctrl_with_saturation.k_fb = 0.00;
    pos_ctrl_with_saturation.k_m = 0.00;
    pos_ctrl_with_saturation.ts_position = 0.00;

    pos_ctrl_with_saturation.kp =  0.00;
    pos_ctrl_with_saturation.ki =  0.00;
    pos_ctrl_with_saturation.kd =  0.00;

    pos_ctrl_with_saturation.gain_p =  1000.00;
    pos_ctrl_with_saturation.gain_i =  1000.00;
    pos_ctrl_with_saturation.gain_d =  1000.00;

    pos_ctrl_with_saturation.feedback_p_loop=0.00;
    pos_ctrl_with_saturation.feedback_d_loop=0.00;
    pos_ctrl_with_saturation.gained_error=0.00;
    pos_ctrl_with_saturation.t_max=0.00;

    pos_ctrl_with_saturation.y_k=0.00;
    pos_ctrl_with_saturation.y_k_sign=0.00;
    pos_ctrl_with_saturation.y_k_1=0.00;
    pos_ctrl_with_saturation.delta_y_k=0.00;

    pos_ctrl_with_saturation.dynamic_max_speed=0.00;
    pos_ctrl_with_saturation.w_max = 0.00;
    pos_ctrl_with_saturation.state_1=0.00;
    pos_ctrl_with_saturation.state_2=0.00;
    pos_ctrl_with_saturation.state_3=0.00;
    pos_ctrl_with_saturation.state_min=0.00;

    pos_ctrl_with_saturation.torque_ref_k=0.00;
}


void position_control_with_saturation_set_parameters(PositionControlWithSaturation &pos_ctrl_with_saturation, PosVelocityControlConfig &pos_velocity_ctrl_config)
{
    //************************************************
    // set parameters of position controller structure
    pos_ctrl_with_saturation.w_max = (((double)(pos_velocity_ctrl_config.max_speed))*2.00*3.1415)/60;
    pos_ctrl_with_saturation.k_fb =((double)(pos_velocity_ctrl_config.k_fb))/1000.00;
    pos_ctrl_with_saturation.k_m  = ((double)(pos_velocity_ctrl_config.k_m))/1000.00;

    //1ms
    pos_ctrl_with_saturation.kp =  ((double)(pos_velocity_ctrl_config.P_saturated_position_controller))/100.00;
    pos_ctrl_with_saturation.ki =  ((double)(pos_velocity_ctrl_config.I_saturated_position_controller))/100.00;
    pos_ctrl_with_saturation.kd =  ((double)(pos_velocity_ctrl_config.D_saturated_position_controller))/100.00;

    pos_ctrl_with_saturation.ts_position = ((double)(pos_velocity_ctrl_config.control_loop_period))/1000000.00; //s


    pos_ctrl_with_saturation.j   = ((double)(pos_velocity_ctrl_config.j)); //s
    pos_ctrl_with_saturation.kp *= pos_ctrl_with_saturation.j;
    pos_ctrl_with_saturation.ki *= pos_ctrl_with_saturation.j;
    pos_ctrl_with_saturation.kd *= pos_ctrl_with_saturation.j;
    pos_ctrl_with_saturation.kp /=1000000.00;
    pos_ctrl_with_saturation.ki /=1000000.00;
    pos_ctrl_with_saturation.kd /=1000000.00;

    pos_ctrl_with_saturation.gain_p = ((double)(pos_velocity_ctrl_config.gain_p));
    pos_ctrl_with_saturation.gain_i = ((double)(pos_velocity_ctrl_config.gain_i));
    pos_ctrl_with_saturation.gain_d = ((double)(pos_velocity_ctrl_config.gain_d));

    pos_ctrl_with_saturation.kp *= (pos_ctrl_with_saturation.gain_p);
    pos_ctrl_with_saturation.kp /= 1000.00;
    pos_ctrl_with_saturation.ki *= (pos_ctrl_with_saturation.gain_i);
    pos_ctrl_with_saturation.ki /= 1000.00;
    pos_ctrl_with_saturation.kd *= (pos_ctrl_with_saturation.gain_d);
    pos_ctrl_with_saturation.kd /= 1000.00;

    pos_ctrl_with_saturation.t_max=((double)(pos_velocity_ctrl_config.max_torque));

}

/**
 * @brief updating the position reference profiler
 * @param output, profiled position calculated for the next step
 * @param input, target position
 * @param input, profiled position calculated in one step ago
 * @param input, profiled position calculated in two steps ago
 * @param the parameters of the position reference profiler
 */
float pos_profiler(float pos_target, float pos_k_1n, float pos_k_2n, posProfilerParam pos_profiler_param)
{
    float velocity_k_1n, temp, deceleration_distance, pos_deceleration, pos_k, pos_temp1, pos_temp2;
    int deceleration_flag = 0;


    if (pos_target == pos_k_1n)
        pos_k = pos_target;
    else if (pos_target > pos_k_1n) {
        if (((pos_k_1n-pos_k_2n)==0) && (pos_target < (pos_k_1n+10)))
            pos_k = pos_k_1n; //ignore the command
        else {
            velocity_k_1n = ((pos_k_1n - pos_k_2n) / pos_profiler_param.delta_T);
            deceleration_distance = (velocity_k_1n * velocity_k_1n) / (2 * pos_profiler_param.a_max);
            pos_deceleration = pos_target - deceleration_distance;
            if ((pos_k_1n >= pos_deceleration) && (pos_k_1n > pos_k_2n))
                deceleration_flag = 1;
            temp = pos_profiler_param.delta_T * pos_profiler_param.delta_T * pos_profiler_param.a_max;
            if (deceleration_flag == 0) {
                pos_temp1 = temp + (2 * pos_k_1n) - pos_k_2n;
                pos_temp2 = (pos_profiler_param.delta_T * pos_profiler_param.v_max) + pos_k_1n;
                if (pos_temp1 < pos_temp2)
                    pos_k = pos_temp1;
                else
                    pos_k = pos_temp2;
            }
            else {
                pos_k = -temp + (2 * pos_k_1n) - pos_k_2n;
            }
            if (pos_k > pos_target)
                pos_k = pos_target;
            if ((pos_k < pos_target) && (sign_function(pos_k_1n-pos_k_2n) > sign_function(pos_k-pos_k_1n)))
                pos_k = pos_target;
        }
    }
    else
    {
        if (((pos_k_1n-pos_k_2n)==0) && (pos_target > (pos_k_1n-10)))
            pos_k = pos_k_1n; //ignore the command
        else {
            velocity_k_1n = ((pos_k_1n - pos_k_2n) / pos_profiler_param.delta_T);
            deceleration_distance = (velocity_k_1n * velocity_k_1n) / (2 * pos_profiler_param.a_max);
            pos_deceleration = pos_target + deceleration_distance;
            if ((pos_k_1n <= pos_deceleration) && (pos_k_1n < pos_k_2n))
                deceleration_flag = 1;
            temp = pos_profiler_param.delta_T * pos_profiler_param.delta_T * pos_profiler_param.a_max;
            if (deceleration_flag == 0) {
                pos_temp1 = -temp + (2 * pos_k_1n) - pos_k_2n;
                pos_temp2 = -(pos_profiler_param.delta_T * pos_profiler_param.v_max) + pos_k_1n;
                if (pos_temp1 > pos_temp2)
                    pos_k = pos_temp1;
                else
                    pos_k = pos_temp2;
            }
            else {
                pos_k = temp + (2 * pos_k_1n) - pos_k_2n;
            }
            if (pos_k < pos_target)
                pos_k = pos_target;
            if ((pos_k > pos_target) && (sign_function(pos_k_1n-pos_k_2n) < sign_function(pos_k-pos_k_1n)))
                pos_k = pos_target;
        }
    }

    return pos_k;
}

