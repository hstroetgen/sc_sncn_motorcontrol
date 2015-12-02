/**
 * @file comm_loop_server.xc
 * @brief Commutation Loop based on sinusoidal commutation method
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <xs1.h>
#include <stdlib.h>
#include <refclk.h>
#include <stdio.h>
#include <print.h>

#include <commutation_service.h>
#include <watchdog_service.h>
#include <pwm_cli_inv.h>
#include <a4935.h>
#include <sine_table_big.h>
#include <qei_service.h>

#include <internal_config.h>


static void commutation_init_to_zero(chanend c_pwm_ctrl, t_pwm_control & pwm_ctrl)
{
    unsigned int pwm[3] = {0, 0, 0};  // PWM OFF (break mode; short all phases)
    pwm_share_control_buffer_address_with_server(c_pwm_ctrl, pwm_ctrl);
    update_pwm_inv(pwm_ctrl, c_pwm_ctrl, pwm);
}

int check_commutation_config(CommutationConfig &commutation_params)
{

    if(commutation_params.nominal_speed <= 0){
        printstrln("Wrong Commutation configuration: wrong nominal speed");
        return ERROR;
    }

    if(commutation_params.winding_type < 0 || commutation_params.winding_type > 2){
        printstrln("Wrong Commutation configuration: wrong winding");
        return ERROR;
    }

    if(commutation_params.angle_variance <= 0){
        printstrln("Wrong Commutation configuration: angle variance");
        return ERROR;
    }

    return SUCCESS;
}

[[combinable]]
void commutation_service(interface HallInterface client i_hall,
                            interface QEIInterface client ?i_qei,
                            interface WatchdogInterface client watchdog_interface,
                            interface CommutationInterface server commutation_interface[5],
                            chanend c_pwm_ctrl,
                            FetDriverPorts &fet_driver_ports,
                            CommutationConfig &commutation_params)
{
    const unsigned t_delay = 300*USEC_FAST;
    timer t;
    unsigned int ts;
    t_pwm_control pwm_ctrl;
    int check_fet;
    int init_state = INIT_BUSY;

    unsigned int pwm[3] = { 0, 0, 0 };
    int angle_pwm = 0;
    int angle = 0;
    int voltage = 0;
    int pwm_half = PWM_MAX_VALUE>>1;
    QEIConfig qei_config;
    HallConfig hall_config = i_hall.getHallConfig();


    if(!isnull(i_qei)){
        qei_config = i_qei.getQEIConfig();
    }

    int max_count_per_hall = qei_config.real_counts/hall_config.pole_pairs;
    int angle_offset = (4096 / 6) / (2 * hall_config.pole_pairs);

    int fw_flag = 0;
    int bw_flag = 0;
    int nominal_speed;
    int shutdown = 0; //Disable FETS
    int sensor_select = HALL;

    if (check_commutation_config(commutation_params) == ERROR){
        printstrln("Error while checking the Commutation configuration");
        return;
    }

    printf("*************************************\n    COMMUTATION SERVER STARTING\n*************************************\n");

    commutation_init_to_zero(c_pwm_ctrl, pwm_ctrl);

    // enable watchdog
    t :> ts;
    t when timerafter (ts + 250000*4):> ts; /* FIXME: replace with constant */
    watchdog_interface.start();

    t :> ts;
    t when timerafter (ts + t_delay) :> ts;

    if (!isnull(fet_driver_ports.p_esf_rst_pwml_pwmh) && !isnull(fet_driver_ports.p_coast)){
        a4935_initialize(fet_driver_ports.p_esf_rst_pwml_pwmh, fet_driver_ports.p_coast, A4935_BIT_PWML | A4935_BIT_PWMH);
        t when timerafter (ts + t_delay) :> ts;
    }

    if(!isnull(fet_driver_ports.p_coast)){
        fet_driver_ports.p_coast :> check_fet;
        init_state = check_fet;
    }
    else {
        watchdog_interface.enable_motors();
        init_state = 1;
    }

    while (1) {

  //      t_loop :> start_time;

        select {

            case t when timerafter(ts + USEC_FAST*40*commutation_params.commutation_loop_freq) :> ts: //XX kHz commutation loop
                if (sensor_select == HALL) {
                    //hall only
                    angle = i_hall.get_hall_position();//get_hall_position(c_hall);
                } else if (sensor_select == QEI && !isnull(i_qei)) {
                    { angle, fw_flag, bw_flag } = i_qei.get_qei_sync_position();
                    angle = (angle << 12) / max_count_per_hall;
                    if ((voltage >= 0 && fw_flag == 0) || (voltage < 0 && bw_flag == 0)) {
                        angle = i_hall.get_hall_position();//get_hall_position(c_hall);
                    }
                }

                if (shutdown == 1) {    /* stop PWM */
                    pwm[0] = -1;
                    pwm[1] = -1;
                    pwm[2] = -1;
                } else {
                    if (voltage >= 0) {
                        if (sensor_select == HALL) {
                            angle_pwm = ((angle + commutation_params.hall_offset_clk) >> 2) & 0x3ff;
                        } else if (sensor_select == QEI ) {
                            angle_pwm = ((angle + commutation_params.qei_forward_offset) >> 2) & 0x3ff; //512
                        }
                        pwm[0] = ((sine_third_expanded(angle_pwm)) * voltage) / pwm_half + pwm_half; // 6944 -- 6867range
                        angle_pwm = (angle_pwm + 341) & 0x3ff; /* +120 degrees (sine LUT size divided by 3) */
                        pwm[1] = ((sine_third_expanded(angle_pwm)) * voltage) / pwm_half + pwm_half;
                        angle_pwm = (angle_pwm + 342) & 0x3ff;
                        pwm[2] = ((sine_third_expanded(angle_pwm)) * voltage) / pwm_half + pwm_half;
                    } else { /* voltage < 0 */
                        if (sensor_select == HALL) {
                            angle_pwm = ((angle + commutation_params.hall_offset_cclk) >> 2) & 0x3ff;
                        } else if (sensor_select == QEI) {
                            angle_pwm = ((angle + commutation_params.qei_backward_offset) >> 2) & 0x3ff; //3100
                        }
                        pwm[0] = ((sine_third_expanded(angle_pwm)) * -voltage) / pwm_half + pwm_half;
                        angle_pwm = (angle_pwm + 341) & 0x3ff;
                        pwm[1] = ((sine_third_expanded(angle_pwm)) * -voltage) / pwm_half + pwm_half;
                        angle_pwm = (angle_pwm + 342) & 0x3ff;
                        pwm[2] = ((sine_third_expanded(angle_pwm)) * -voltage) / pwm_half + pwm_half;
                    }
                }

                /* Limiting PWM values (and suppression of short pulses) is done in
                 * update_pwm_inv() */
                update_pwm_inv(pwm_ctrl, c_pwm_ctrl, pwm);
                break;


            case commutation_interface[int i].setVoltage(int new_voltage):
                    voltage = new_voltage;
                    if (commutation_params.winding_type == DELTA_WINDING) {
                        voltage = -voltage;
                    }
                    break;

            case commutation_interface[int i].setParameters(CommutationConfig new_parameters):
                    commutation_params.angle_variance = new_parameters.angle_variance;
                    commutation_params.nominal_speed = new_parameters.nominal_speed;
                    commutation_params.hall_offset_clk = new_parameters.hall_offset_clk;
                    commutation_params.hall_offset_cclk = new_parameters.hall_offset_cclk;
                    commutation_params.winding_type = new_parameters.winding_type;

                    break;

            case commutation_interface[int i].setSensor(int new_sensor):
                    sensor_select = new_sensor;
                    break;

            case commutation_interface[int i].enableFets():
                    shutdown = 0;
                    voltage = 0;
                    break;

            case commutation_interface[int i].disableFets():
                    shutdown = 1;
                    break;

            case commutation_interface[int i].getFetsState() -> int fets_state:
                    fets_state = shutdown;
                    break;

            case commutation_interface[int i].checkBusy() -> int state_return:
                    state_return = init_state;
                    break;

            case commutation_interface[int i].setAllParameters(HallConfig in_hall_config,
                                                                QEIConfig in_qei_config,
                                                                CommutationConfig in_commutation_config, int in_nominal_speed):

                 hall_config.pole_pairs = in_hall_config.pole_pairs;
                 qei_config.index = in_qei_config.index;
                 qei_config.max_ticks_per_turn = in_qei_config.max_ticks_per_turn;
                 qei_config.real_counts = in_qei_config.real_counts;
                 nominal_speed = in_nominal_speed;
                 commutation_params.hall_offset_clk = in_commutation_config.hall_offset_clk;
                 commutation_params.hall_offset_cclk = in_commutation_config.hall_offset_cclk;
                 commutation_params.winding_type = in_commutation_config.winding_type;
                 commutation_params.angle_variance = (60 * 4096) / (hall_config.pole_pairs * 2 * 360);

                 if (hall_config.pole_pairs < 4) {
                      commutation_params.nominal_speed = nominal_speed * 4;
                  } else if (hall_config.pole_pairs >= 4) {
                      commutation_params.nominal_speed = nominal_speed;
                  }
                  commutation_params.qei_forward_offset = 0;
                  commutation_params.qei_backward_offset = 0;
                  voltage = 0;
                  max_count_per_hall = qei_config.real_counts / hall_config.pole_pairs;
                  angle_offset = (4096 / 6) / (2 * hall_config.pole_pairs);
                  fw_flag = 0;
                  bw_flag = 0;

                    break;

            }

 //       t_loop :> end_time;
 //       printf("%i kHz\n", 250000/(end_time - start_time));
    }

}
