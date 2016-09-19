/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IFM_BOARD_REQUIRED" WITH AN APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_C22-rev-a.bsp>
#include <IFM_DC1K-rev-c3.bsp>


/**
 * @brief Test illustrates usage of module_commutation
 * @date 17/06/2014
 */

//#include <pwm_service.h>
#include <pwm_server.h>
#include <adc_service.h>
#include <user_config.h>
#include <tuning.h>
#include <motor_control_interfaces.h>
#include <advanced_motor_control.h>
#include <advanced_motorcontrol_licence.h>
#include <position_feedback_service.h>

PwmPorts pwm_ports = SOMANET_IFM_PWM_PORTS;
WatchdogPorts wd_ports = SOMANET_IFM_WATCHDOG_PORTS;
FetDriverPorts fet_driver_ports = SOMANET_IFM_FET_DRIVER_PORTS;
ADCPorts adc_ports = SOMANET_IFM_ADC_PORTS;
HallPorts hall_ports = SOMANET_IFM_HALL_PORTS;
SPIPorts spi_ports = SOMANET_IFM_AMS_PORTS;
QEIPorts qei_ports = SOMANET_IFM_QEI_PORTS;

#define POSITION_LIMIT 1500000 //+/- 4095



int main(void) {

    // Motor control interfaces
    interface WatchdogInterface i_watchdog[2];
    interface update_pwm i_update_pwm;
    interface ADCInterface i_adc[2];
    interface MotorcontrolInterface i_motorcontrol[4];
    interface PositionVelocityCtrlInterface i_position_control[3];
    interface PositionFeedbackInterface i_position_feedback[3];
    interface shared_memory_interface i_shared_memory[2];
    interface PositionLimiterInterface i_position_limiter;

    par
    {
        /* WARNING: only one blocking task is possible per tile. */
        /* Waiting for a user input blocks other tasks on the same tile from execution. */

        on tile[APP_TILE]: run_offset_tuning(i_motorcontrol[0], i_position_control[1]);

        on tile[APP_TILE_2]:
        /* Position Control Loop */
        {
            PosVelocityControlConfig pos_velocity_ctrl_config;
            /* Control Loop */
            pos_velocity_ctrl_config.control_loop_period =                  CONTROL_LOOP_PERIOD; //us

            pos_velocity_ctrl_config.min_pos =                              MIN_POSITION_LIMIT;
            pos_velocity_ctrl_config.max_pos =                              MAX_POSITION_LIMIT;
            pos_velocity_ctrl_config.max_speed =                            MAX_VELOCITY;
            pos_velocity_ctrl_config.max_torque =                           MAX_TORQUE;

            pos_velocity_ctrl_config.enable_profiler =                      ENABLE_PROFILER;
            pos_velocity_ctrl_config.max_acceleration_profiler =            MAX_ACCELERATION_PROFILER;
            pos_velocity_ctrl_config.max_speed_profiler =                   MAX_SPEED_PROFILER;

            pos_velocity_ctrl_config.control_mode =                         POS_WITH_SATURATION_CONTROLLER;

            pos_velocity_ctrl_config.P_pos =                                Kp_POS_PID;
            pos_velocity_ctrl_config.I_pos =                                Ki_POS_PID;
            pos_velocity_ctrl_config.D_pos =                                Kd_POS_PID;
            pos_velocity_ctrl_config.integral_limit_pos =                   INTEGRAL_LIMIT_POS_PID;

            pos_velocity_ctrl_config.P_velocity =                           Kp_VELOCITY_PID;
            pos_velocity_ctrl_config.I_velocity =                           Ki_VELOCITY_PID;
            pos_velocity_ctrl_config.D_velocity =                           Kd_VELOCITY_PID;
            pos_velocity_ctrl_config.integral_limit_velocity =              INTEGRAL_LIMIT_VELOCITY_PID;

            pos_velocity_ctrl_config.P_pos_Integral_optimum =               Kp_POS_INTEGRAL_OPTIMUM;
            pos_velocity_ctrl_config.I_pos_Integral_optimum =               Ki_POS_INTEGRAL_OPTIMUM;
            pos_velocity_ctrl_config.D_pos_Integral_optimum =               Kd_POS_INTEGRAL_OPTIMUM;
            pos_velocity_ctrl_config.integral_limit_pos_Integral_optimum =  INTEGRAL_LIMIT_POS_INTEGRAL_OPTIMUM;

            pos_velocity_ctrl_config.position_fc =                          POSITION_FC;
            pos_velocity_ctrl_config.velocity_fc =                          VELOCITY_FC;

            pos_velocity_ctrl_config.P_saturated_position_controller =      Kp_SATURATED_POS_CONTROL;
            pos_velocity_ctrl_config.I_saturated_position_controller =      Ki_SATURATED_POS_CONTROL;
            pos_velocity_ctrl_config.D_saturated_position_controller =      Kd_SATURATED_POS_CONTROL;

            pos_velocity_ctrl_config.gain_p =                               GAIN_P;
            pos_velocity_ctrl_config.gain_i =                               GAIN_I;
            pos_velocity_ctrl_config.gain_d =                               GAIN_D;

            pos_velocity_ctrl_config.k_fb =                                 K_FB;
            pos_velocity_ctrl_config.k_m =                                  K_M;

            pos_velocity_ctrl_config.j =                                    MOMENT_OF_INERTIA;

            position_velocity_control_service(pos_velocity_ctrl_config, i_motorcontrol[3], i_position_control);
        }


        on tile[IFM_TILE]:
        {
            par
            {
                /* PWM Service */
                {
                    pwm_config(pwm_ports);

                    delay_milliseconds(10);
                    if (!isnull(fet_driver_ports.p_esf_rst_pwml_pwmh) && !isnull(fet_driver_ports.p_coast))
                        predriver(fet_driver_ports);

                    delay_milliseconds(5);
                    //pwm_check(pwm_ports);//checks if pulses can be generated on pwm ports or not
                    pwm_service_task(_MOTOR_ID, pwm_ports, i_update_pwm, DUTY_START_BRAKE, DUTY_MAINTAIN_BRAKE, PERIOD_START_BRAKE);
                }

                /* ADC Service */
                {
                    delay_milliseconds(10);
                    adc_service(adc_ports, null/*c_trigger*/, i_adc /*ADCInterface*/, i_watchdog[1]);
                }

                /* Watchdog Service */
                {
                    delay_milliseconds(5);
                    watchdog_service(wd_ports, i_watchdog);
                }

                /* Motor Control Service */
                {
                    delay_milliseconds(20);

                    MotorcontrolConfig motorcontrol_config;

                    motorcontrol_config.licence =  ADVANCED_MOTOR_CONTROL_LICENCE;
                    motorcontrol_config.v_dc =  VDC;
                    motorcontrol_config.commutation_loop_period =  COMMUTATION_LOOP_PERIOD;
                    motorcontrol_config.commutation_angle_offset=COMMUTATION_OFFSET_CLK;
                    motorcontrol_config.polarity_type=MOTOR_POLARITY;
                    motorcontrol_config.current_P_gain =  TORQUE_Kp;
                    motorcontrol_config.current_I_gain =  TORQUE_Ki;
                    motorcontrol_config.current_D_gain =  TORQUE_Kd;
                    motorcontrol_config.pole_pair =  POLE_PAIRS;
                    motorcontrol_config.max_torque =  MAXIMUM_TORQUE;
                    motorcontrol_config.phase_resistance =  PHASE_RESISTANCE;
                    motorcontrol_config.phase_inductance =  PHASE_INDUCTANCE;
                    motorcontrol_config.torque_constant =  PERCENT_TORQUE_CONSTANT;
                    motorcontrol_config.current_ratio =  CURRENT_RATIO;
                    motorcontrol_config.rated_current =  RATED_CURRENT;
                    motorcontrol_config.rated_torque  =  RATED_TORQUE;
                    motorcontrol_config.percent_offset_torque =  PERCENT_OFFSET_TORQUE;
                    motorcontrol_config.recuperation = RECUPERATION;
                    motorcontrol_config.battery_e_max = BATTERY_E_MAX;
                    motorcontrol_config.battery_e_min = BATTERY_E_MIN;
                    motorcontrol_config.regen_p_max = REGEN_P_MAX;
                    motorcontrol_config.regen_p_min = REGEN_P_MIN;
                    motorcontrol_config.regen_speed_max = REGEN_SPEED_MAX;
                    motorcontrol_config.regen_speed_min = REGEN_SPEED_MIN;
                    motorcontrol_config.protection_limit_over_current =  I_MAX;
                    motorcontrol_config.protection_limit_over_voltage =  V_DC_MAX;
                    motorcontrol_config.protection_limit_under_voltage = V_DC_MIN;

                    Motor_Control_Service(motorcontrol_config, i_adc[0], i_shared_memory[1],
                            i_watchdog[0], i_motorcontrol, i_update_pwm);
                }

                /* Shared memory Service */
                {
                    memory_manager(i_shared_memory, 2);
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

                    position_feedback_config.hall_config.pole_pairs = POLE_PAIRS;
                    position_feedback_config.hall_config.enable_push_service = PushAll;

                    position_feedback_config.qei_config.ticks_resolution = QEI_SENSOR_RESOLUTION;
                    position_feedback_config.qei_config.index_type = QEI_SENSOR_INDEX_TYPE;
                    position_feedback_config.qei_config.sensor_polarity = QEI_SENSOR_POLARITY;
                    position_feedback_config.qei_config.signal_type = QEI_SENSOR_SIGNAL_TYPE;
                    position_feedback_config.qei_config.enable_push_service = PushPosition;

                    position_feedback_service(hall_ports, qei_ports, spi_ports,
                                              position_feedback_config, i_shared_memory[0], i_position_feedback,
                                              null, null, null);
                }
            }
        }
    }

    return 0;
}
