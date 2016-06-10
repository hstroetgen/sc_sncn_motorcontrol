/* INCLUDE BOARD SUPPORT FILES FROM module_board-support */
#include <CORE_C22-rev-a.bsp>
#include <IFM_DC1K-rev-c3.bsp>

/**
 * @file test_position-ctrl.xc
 * @brief Test illustrates usage of profile position control
 * @author Synapticon GmbH (www.synapticon.com)
 */

//BLDC Motor drive libs
#include <position_feedback_service.h>
#include <pwm_server.h>
#include <watchdog_service.h>
#include <torque_control.h>

//Position control + profile libs
#include <position_ctrl_service.h>
#include <profile_control.h>

//Configuration headers
#include <user_config.h>

PwmPorts pwm_ports = SOMANET_IFM_PWM_PORTS;
WatchdogPorts wd_ports = SOMANET_IFM_WATCHDOG_PORTS;
ADCPorts adc_ports = SOMANET_IFM_ADC_PORTS;
FetDriverPorts fet_driver_ports = SOMANET_IFM_FET_DRIVER_PORTS;
PositionFeedbackPorts position_feedback_ports = SOMANET_IFM_POSITION_FEEDBACK_PORTS;

/* Test Profile Position function */
void position_profile_test(interface PositionVelocityCtrlInterface client i_position_control, client interface PositionFeedbackInterface ?i_position_feedback)
{
    const int target = 655360;
//    const int target = 2620000;
    int target_position = target;        // HALL: 1 rotation = 4096 x nr. pole pairs; QEI: your encoder documented resolution x 4 = one rotation
    int velocity        = 500;         // rpm
    int acceleration    = 500;         // rpm/s
    int deceleration    = 500;         // rpm/s
    int follow_error = 0;
    int actual_position = 0;

    ProfilerConfig profiler_config;
    profiler_config.polarity = POLARITY;
    profiler_config.max_position = MAX_POSITION_LIMIT;
    profiler_config.min_position = MIN_POSITION_LIMIT;
    if (!isnull(i_position_feedback)) {
        profiler_config.ticks_per_turn = i_position_feedback.get_ticks_per_turn();
    } else {
        profiler_config.ticks_per_turn = QEI_SENSOR_RESOLUTION;
    }
    profiler_config.max_velocity = MAX_VELOCITY;
    profiler_config.max_acceleration = MAX_ACCELERATION;
    profiler_config.max_deceleration = MAX_DECELERATION;

    int start_position = i_position_control.get_position();
    target_position = start_position + target;

    /* Initialise the position profile generator */
    init_position_profiler(profiler_config);

    delay_milliseconds(500);//let the servers start before sending client requests

    /* Set new target position for profile position control */
    set_profile_position(target_position, velocity, acceleration, deceleration, i_position_control);

    while(1)
    {
        // Read actual position from the Position Control Server
        actual_position = i_position_control.get_position();
        follow_error = target_position - actual_position;

        /*
        xscope_core_int(0, actual_position);
        xscope_core_int(1, target_position);
        xscope_core_int(2, follow_error);
        */
        // Keep motor turning when reaching target position
        if (follow_error < 200 && follow_error > -200){
            if (target_position == (start_position + target)){
                target_position = start_position - target;
            } else {
                target_position = start_position + target;
            }
            set_profile_position(target_position, velocity, acceleration, deceleration, i_position_control);
        }
        delay_milliseconds(1);
    }
}


int main(void)
{
    // Motor control channels

    interface WatchdogInterface i_watchdog[2];
    interface ADCInterface i_adc[2];
    interface MotorcontrolInterface i_motorcontrol[4];
    interface update_pwm i_update_pwm;
    interface shared_memory_interface i_shared_memory[2];
    interface PositionVelocityCtrlInterface i_position_control[3];
    interface PositionFeedbackInterface i_position_feedback[3];

    par
    {
        /* Test Profile Position Client function*/
        on tile[APP_TILE]:
        {
            position_profile_test(i_position_control[0], i_position_feedback[0]);      // test PPM on slave side
        }

//        on tile[APP_TILE]:
//        /* XScope monitoring */
//        {
//            int actual_position, target_position, actual_velocity;
//
//            while(1)
//            {
//                /* Read actual position from the Position Control Server */
//                actual_velocity = i_position_control[1].get_velocity();
//                actual_position = i_position_control[1].get_position();
//                target_position = i_position_control[1].get_target_position();
//
//                xscope_int(TARGET_POSITION, target_position); //Divided by 10 for better displaying
//                xscope_int(ACTUAL_POSITION, actual_position); //Divided by 10 for better displaying
//                xscope_int(VELOCITY, actual_velocity);
////                xscope_int(FOLLOW_ERROR, (target_position-actual_position)); //Divided by 10 for better displaying
//
//                delay_milliseconds(1); /* 1 ms wait */
//            }
//        }

        on tile[APP_TILE]:
        /* Position Control Loop */
        {
            PosVelocityControlConfig pos_velocity_ctrl_config;
            /* Control Loop */
            pos_velocity_ctrl_config.control_loop_period = CONTROL_LOOP_PERIOD; //us

            pos_velocity_ctrl_config.int21_min_position = MIN_POSITION_LIMIT;
            pos_velocity_ctrl_config.int21_max_position = MAX_POSITION_LIMIT;
            pos_velocity_ctrl_config.int21_max_speed = MAX_VELOCITY;
            pos_velocity_ctrl_config.int21_max_torque = MAX_TORQUE;


            pos_velocity_ctrl_config.int10_P_position = POSITION_Kp;
            pos_velocity_ctrl_config.int10_I_position = POSITION_Ki;
            pos_velocity_ctrl_config.int10_D_position = POSITION_Kd;
            pos_velocity_ctrl_config.int21_P_error_limit_position = POSITION_P_ERROR_lIMIT;
            pos_velocity_ctrl_config.int21_I_error_limit_position = POSITION_I_ERROR_lIMIT;
            pos_velocity_ctrl_config.int22_integral_limit_position = POSITION_INTEGRAL_LIMIT;

            pos_velocity_ctrl_config.int10_P_velocity = VELOCITY_Kp;
            pos_velocity_ctrl_config.int10_I_velocity = VELOCITY_Ki;
            pos_velocity_ctrl_config.int10_D_velocity = VELOCITY_Kd;
            pos_velocity_ctrl_config.int21_P_error_limit_velocity = VELOCITY_P_ERROR_lIMIT;
            pos_velocity_ctrl_config.int21_I_error_limit_velocity = VELOCITY_I_ERROR_lIMIT;
            pos_velocity_ctrl_config.int22_integral_limit_velocity = VELOCITY_INTEGRAL_LIMIT;

            pos_velocity_ctrl_config.position_ref_fc = POSITION_REF_FC;
            pos_velocity_ctrl_config.position_fc = POSITION_FC;
            pos_velocity_ctrl_config.velocity_ref_fc = VELOCITY_REF_FC;
            pos_velocity_ctrl_config.velocity_fc = VELOCITY_FC;
            pos_velocity_ctrl_config.velocity_d_fc = VELOCITY_D_FC;

            position_velocity_control_service(pos_velocity_ctrl_config, i_motorcontrol[3], i_position_control);
        }

        /************************************************************
         * IFM_TILE
         ************************************************************/
        on tile[IFM_TILE]:
        {
            par
            {
                /* PWM Service */
                {
                    pwm_config(pwm_ports);
                    //pwm_check(pwm_ports);//checks if pulses can be generated on pwm ports or not
                    delay_milliseconds(1000);
                    pwm_service_task(_MOTOR_ID, pwm_ports, i_update_pwm);
                }

                /* ADC Service */
                {
                    delay_milliseconds(1500);
                    adc_service(adc_ports, null/*c_trigger*/, i_adc /*ADCInterface*/, i_watchdog[1]);
                }

                /* Watchdog Service */
                {
                    delay_milliseconds(500);
                    watchdog_service(wd_ports, i_watchdog);
                }

                /* Position feedback service */
                {
                    PositionFeedbackConfig position_feedback_config;
                    position_feedback_config.sensor_type = MOTOR_COMMUTATION_SENSOR;

                    position_feedback_config.biss_config.multiturn_length = BISS_MULTITURN_LENGTH;
                    position_feedback_config.biss_config.multiturn_resolution = BISS_MULTITURN_RESOLUTION;
                    position_feedback_config.biss_config.singleturn_length = BISS_SINGLETURN_LENGTH;
                    position_feedback_config.biss_config.singleturn_resolution = BISS_SINGLETURN_RESOLUTION;
                    position_feedback_config.biss_config.status_length = BISS_STATUS_LENGTH;
                    position_feedback_config.biss_config.crc_poly = BISS_CRC_POLY;
                    position_feedback_config.biss_config.pole_pairs = POLE_PAIRS;
                    position_feedback_config.biss_config.polarity = BISS_POLARITY;
                    position_feedback_config.biss_config.clock_dividend = BISS_CLOCK_DIVIDEND;
                    position_feedback_config.biss_config.clock_divisor = BISS_CLOCK_DIVISOR;
                    position_feedback_config.biss_config.timeout = BISS_TIMEOUT;
                    position_feedback_config.biss_config.max_ticks = BISS_MAX_TICKS;
                    position_feedback_config.biss_config.velocity_loop = BISS_VELOCITY_LOOP;
                    position_feedback_config.biss_config.offset_electrical = BISS_OFFSET_ELECTRICAL;
                    position_feedback_config.biss_config.enable_push_service = PushAll;

                    position_feedback_config.contelec_config.filter = CONTELEC_FILTER;
                    position_feedback_config.contelec_config.polarity = CONTELEC_POLARITY;
                    position_feedback_config.contelec_config.resolution_bits = CONTELEC_RESOLUTION;
                    position_feedback_config.contelec_config.offset = CONTELEC_OFFSET;
                    position_feedback_config.contelec_config.pole_pairs = POLE_PAIRS;
                    position_feedback_config.contelec_config.timeout = CONTELEC_TIMEOUT;
                    position_feedback_config.contelec_config.velocity_loop = CONTELEC_VELOCITY_LOOP;
                    position_feedback_config.contelec_config.enable_push_service = PushAll;

                    position_feedback_service(position_feedback_ports, position_feedback_config, i_shared_memory[1], i_position_feedback, null, null, null, null);
                }

                /* Shared memory Service */
                memory_manager(i_shared_memory, 2);

                /* Motor Control Service */
                {
                    delay_milliseconds(2000);

                    MotorcontrolConfig motorcontrol_config;

                    motorcontrol_config.v_dc =  VDC;
                    motorcontrol_config.commutation_loop_period =  COMMUTATION_LOOP_PERIOD;
                    motorcontrol_config.commutation_angle_offset=COMMUTATION_OFFSET_CLK;
                    motorcontrol_config.polarity_type=MOTOR_POLARITY;

                    motorcontrol_config.current_P_gain =  TORQUE_Kp;

                    motorcontrol_config.pole_pair =  POLE_PAIRS;
                    motorcontrol_config.max_torque =  MAXIMUM_TORQUE;
                    motorcontrol_config.phase_resistance =  PHASE_RESISTANCE;
                    motorcontrol_config.phase_inductance =  PHASE_INDUCTANCE;

                    motorcontrol_config.protection_limit_over_current =  I_MAX;
                    motorcontrol_config.protection_limit_over_voltage =  V_DC_MAX;
                    motorcontrol_config.protection_limit_under_voltage = V_DC_MIN;

                    Motor_Control_Service( fet_driver_ports, motorcontrol_config, i_adc[0],
                            i_shared_memory[0],
                            i_watchdog[0], i_motorcontrol, i_update_pwm);
                }
            }
        }
    }

    return 0;
}
