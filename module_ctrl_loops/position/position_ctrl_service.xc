/**
 * @file  position_ctrl_server.xc
 * @brief Position Control Loop Server Implementation
 * @author Synapticon GmbH <support@synapticon.com>
*/

#include <xscope.h>
#include <print.h>

#include <position_ctrl_service.h>
#include <a4935.h>
#include <internal_config.h>
#include <hall_service.h>
#include <qei_service.h>






int init_position_control(interface PositionControlInterface client i_position_control)
{
    int ctrl_state = INIT_BUSY;

    while (1) {
        ctrl_state = i_position_control.check_position_ctrl_state();
        if (ctrl_state == INIT_BUSY) {
            i_position_control.enable_position_ctrl();
        }

        if (ctrl_state == INIT) {
#ifdef debug_print
            printstrln("position control intialized");
#endif
            break;
        }
    }
    return ctrl_state;
}

int position_limit(int position, int max_position_limit, int min_position_limit)
{
    if (position > max_position_limit) {
        position = max_position_limit;
    } else if (position < min_position_limit) {
        position = min_position_limit;
    }
    return position;
}

void set_position_csp( ProfilerConfig & csp_params, int target_position, int position_offset,
                       int velocity_offset, int torque_offset, interface PositionControlInterface client i_position_control )
{
    i_position_control.set_position( position_limit( (target_position + position_offset) * csp_params.polarity,
                                  csp_params.max_position,
                                  csp_params.min_position));
}


void position_control_service(ControlConfig &position_control_config,
                                interface HallInterface client ?i_hall,
                                interface QEIInterface client ?i_qei,
                                interface MotorcontrolInterface client i_motorcontrol,
                                interface PositionControlInterface server i_position_control[3])
{
    int actual_position = 0;
    int target_position = 0;

    int error_position = 0;
    int error_position_D = 0;
    int error_position_I = 0;
    int previous_error = 0;
    int position_control_out = 0;

    int position_control_out_limit = 0;
    int error_position_I_limit = 0;

    timer t;
    unsigned int ts;

    int activate = 0;
    int direction = 0;

    int fet_state;
    int init_state = INIT_BUSY; /* check commutation init */

    HallConfig hall_config;
    QEIConfig qei_config;
    MotorcontrolConfig motorcontrol_config = i_motorcontrol.get_config();

   if(position_control_config.feedback_sensor != HALL_SENSOR
           && position_control_config.feedback_sensor < QEI_SENSOR){
       position_control_config.feedback_sensor = motorcontrol_config.commutation_sensor;
   }


    if(position_control_config.feedback_sensor == HALL_SENSOR){
        if(isnull(i_hall)){
            printstrln("Position Control Loop ERROR: Interface for Hall Service not provided");
        }else{
            hall_config = i_hall.get_hall_config();
        }
    } else if(position_control_config.feedback_sensor >= QEI_SENSOR && !isnull(i_qei)){
        if(isnull(i_qei)){
            printstrln("Position Control Loop ERROR: Interface for QEI Service not provided");
        }else{
            qei_config = i_qei.get_qei_config();
        }
    }



    //Limits
    if(motorcontrol_config.motor_type == BLDC_MOTOR){
        position_control_out_limit = BLDC_PWM_CONTROL_LIMIT;
    }else if(motorcontrol_config.motor_type == BDC_MOTOR){
        position_control_out_limit = BDC_PWM_CONTROL_LIMIT;
    }

    if(position_control_config.Ki != 0)
        error_position_I_limit = position_control_out_limit * PID_DENOMINATOR / position_control_config.Ki;


    printstr("*************************************\n    POSITION CONTROLLER STARTING\n*************************************\n");

    if (position_control_config.feedback_sensor == HALL_SENSOR && !isnull(i_hall)) {
        { actual_position, direction } = i_hall.get_hall_position_absolute();
        target_position = actual_position;
    } else if (position_control_config.feedback_sensor >= QEI_SENSOR && !isnull(i_qei)) {
        {actual_position, direction} = i_qei.get_qei_position_absolute();
        target_position = actual_position;
    }

    /*
     * Or any other sensor interfaced to the IFM Module
     * place client functions here to acquire position
     */

    t :> ts;

    while(1) {
#pragma ordered
        select {
        case t when timerafter(ts + USEC_STD * position_control_config.control_loop_period) :> ts:
            if (activate == 1) {
                /* acquire actual position hall/qei/sensor */
                switch (position_control_config.feedback_sensor) {
                    case HALL_SENSOR:
                    { actual_position, direction } = i_hall.get_hall_position_absolute();//get_hall_position_absolute(c_hall);
                    break;

                    case QEI_SENSOR:
                    { actual_position, direction } =  i_qei.get_qei_position_absolute();
                    break;

                    case QEI_WITH_INDEX:
                    { actual_position, direction } =  i_qei.get_qei_position_absolute();
                    break;

                    case QEI_WITH_NO_INDEX:
                    { actual_position, direction } =  i_qei.get_qei_position_absolute();
                    break;

                /*
                 * Or any other sensor interfaced to the IFM Module
                 * place client functions here to acquire position
                 */
                }

                /* PID Controller */

                error_position = (target_position - actual_position);
                error_position_I = error_position_I + error_position;
                error_position_D = error_position - previous_error;

                if (error_position_I > error_position_I_limit) {
                    error_position_I = error_position_I_limit;
                } else if (error_position_I < -error_position_I_limit) {
                    error_position_I = - error_position_I_limit;
                }

                position_control_out = (position_control_config.Kp * error_position) +
                                       (position_control_config.Ki * error_position_I) +
                                       (position_control_config.Kd * error_position_D);

                position_control_out /= PID_DENOMINATOR;

                if (position_control_out > position_control_out_limit) {
                    position_control_out = position_control_out_limit;
                } else if (position_control_out < -position_control_out_limit) {
                    position_control_out =  -position_control_out_limit;
                }


               // set_commutation_sinusoidal(c_commutation, position_control_out);
                i_motorcontrol.set_voltage(position_control_out);

#ifdef DEBUG
                xscope_int(ACTUAL_POSITION, actual_position);
                xscope_int(TARGET_POSITION, target_position);
#endif
                //xscope_int(TARGET_POSITION, target_position);
                previous_error = error_position;
            }

            break;

        case i_position_control[int i].set_position(int in_target_position):

            target_position = in_target_position;

            break;

        case i_position_control[int i].get_position() -> int out_position:

                out_position = actual_position;
                break;

        case i_position_control[int i].get_target_position() -> int out_set_position:

                out_set_position = target_position;
                break;

        case i_position_control[int i].check_busy() -> int out_activate:

                out_activate = activate;
                break;

        case i_position_control[int i].set_position_ctrl_param(ControlConfig in_params):

            position_control_config.Kp = in_params.Kp;
            position_control_config.Ki = in_params.Ki;
            position_control_config.Kd = in_params.Kd;

            error_position_I_limit = 0;
            if(position_control_config.Ki != 0)
                error_position_I_limit = position_control_out_limit * PID_DENOMINATOR / position_control_config.Ki;;

            break;

        case i_position_control[int i].set_position_ctrl_hall_param(HallConfig in_config):

            hall_config.pole_pairs = in_config.pole_pairs;
            break;

        case i_position_control[int i].set_position_ctrl_qei_param(QEIConfig in_qei_params):

            qei_config.index_type = in_qei_params.index_type;
            qei_config.ticks_resolution = in_qei_params.ticks_resolution;
            //qei_config.max_ticks_per_turn = in_qei_params.max_ticks_per_turn;
            break;

        case i_position_control[int i].set_position_sensor(int in_sensor_used):

            position_control_config.feedback_sensor = in_sensor_used;

            if (in_sensor_used == HALL_SENSOR) {
                { actual_position, direction }= i_hall.get_hall_position_absolute();
            } else if (in_sensor_used >= QEI_SENSOR) {
                { actual_position, direction } = i_qei.get_qei_position_absolute();
            }
            /*
             * Or any other sensor interfaced to the IFM Module
             * place client functions here to acquire position
             */
            target_position = actual_position;

            break;

        case i_position_control[int i].enable_position_ctrl():
                        activate = 1;
                            while (1) {
                                init_state = i_motorcontrol.check_busy(); //__check_commutation_init(c_commutation);
                                if(init_state == INIT) {
            #ifdef debug_print
                                    printstrln("commutation intialized");
            #endif
                                    fet_state = i_motorcontrol.get_fets_state(); // check_fet_state(c_commutation);
                                    if (fet_state == 1) {
                                        i_motorcontrol.enable_fets();
                                        delay_milliseconds(2);
                                    }

                                    break;
                                }
                            }
            #ifdef debug_print
                            printstrln("position control activated");
            #endif
                            break;

        case i_position_control[int i].shutdown_position_ctrl():
            activate = 0;
            i_motorcontrol.set_voltage(0);
            //set_commutation_sinusoidal(c_commutation, 0);
            error_position = 0;
            error_position_D = 0;
            error_position_I = 0;
            previous_error = 0;
            position_control_out = 0;
            i_motorcontrol.disable_fets();
            // disable_motor(c_commutation);
            delay_milliseconds(30);
            //wait_ms(30, 1, ts); //
#ifdef debug_print
            printstrln("position control disabled");
#endif
            break;

        case i_position_control[int i].check_position_ctrl_state() -> int out_state:
                out_state = activate;

                break;

        case i_position_control[int i].get_control_config() ->  ControlConfig out_config:

                out_config = position_control_config;
                break;
        case i_position_control[int i].get_hall_config() -> HallConfig out_config:

                out_config = hall_config;
                break;
        case i_position_control[int i].get_qei_config() -> QEIConfig out_config:

                out_config = qei_config;
                break;

        }
        }

    }

