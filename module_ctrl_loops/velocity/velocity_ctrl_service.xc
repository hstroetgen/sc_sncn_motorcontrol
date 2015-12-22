/**
 * @file velocity_ctrl_server.xc
 * @brief Velocity Control Loop Server Implementation
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <velocity_ctrl_service.h>
#include <motorcontrol_service.h>
#include <internal_config.h>

#include <filter_blocks.h>
#include <limits.h>
#include <refclk.h>
#include <print.h>




int init_velocity_control(interface VelocityControlInterface client i_velocity_control)
{
    int ctrl_state = INIT_BUSY;

    while (1) {
        ctrl_state = i_velocity_control.check_velocity_ctrl_state(); //check_velocity_ctrl_state(c_velocity_ctrl);
        if (ctrl_state == INIT_BUSY) {
            i_velocity_control.enable_velocity_ctrl();
        }

        if(ctrl_state == INIT) {
#ifdef debug_print
            printstrln("velocity control intialized");
#endif
            break;
        }
    }
    return ctrl_state;
}

int max_speed_limit(int velocity, int max_speed) {
    if (velocity > max_speed) {
        velocity = max_speed;
    } else if (velocity < -max_speed) {
        velocity = -max_speed;
    }
    return velocity;
}

//csv mode function
void set_velocity_csv(ProfilerConfig &csv_params, int target_velocity,
                      int velocity_offset, int torque_offset, interface VelocityControlInterface client i_velocity_control)
{
    i_velocity_control.set_velocity( max_speed_limit( (target_velocity + velocity_offset) * csv_params.polarity,
                                   csv_params.max_velocity ));
}

[[combinable]]
void velocity_control_service(ControlConfig &velocity_control_config,
                       interface HallInterface client ?i_hall,
                       interface QEIInterface client ?i_qei,
                       interface MotorcontrolInterface client i_motorcontrol,
                       interface VelocityControlInterface server i_velocity_control[3])
{
    /* Controller declarations */
    int actual_velocity = 0;
    int target_velocity = 0;
    int error_velocity = 0;
    int error_velocity_D = 0;
    int error_velocity_I = 0;
    int previous_error = 0;
    int velocity_control_out = 0;

    int velocity_control_out_limit = 0;
    int error_velocity_I_limit = 0;

    timer t;
    unsigned int ts;

    /* Sensor filter declarations */
    int filter_length = DEFAULT_FILTER_LENGTH; //sensor_filter_params.filter_length;
    int filter_buffer[FILTER_SIZE_MAX] = {0};   //default size used at compile ts (cant be changed further)
    int index = 0;

    /* speed calc declarations */
    int position;
    int init = 0;
    int previous_position = 0;
    int raw_speed = 0;                      // rpm
    int difference;
    int direction = 0;
    int old_difference;
    int rpm_constant = 1000*60; // constant
    int speed_factor_hall = 0;
    int speed_factor_qei = 0;
    int activate = 0;
    int init_state = INIT_BUSY;
    int qei_crossover = 0;
    int const hall_crossover = INT_MAX - INT_MAX/10;
    int compute_flag = 0;
    int fet_state = 0;

    HallConfig hall_config;
    QEIConfig qei_config;
    MotorcontrolConfig motorcontrol_config = i_motorcontrol.getConfig();

   if(velocity_control_config.feedback_sensor != HALL_SENSOR
           && velocity_control_config.feedback_sensor < QEI_SENSOR){
       velocity_control_config.feedback_sensor = motorcontrol_config.commutation_sensor;
   }

    if(velocity_control_config.feedback_sensor == HALL_SENSOR){
        if(isnull(i_hall)){
            printstrln("Velocity Control Loop ERROR: Interface for Hall Service not provided");
        }else{
            hall_config = i_hall.getHallConfig();
        }
    } else if(velocity_control_config.feedback_sensor >= QEI_SENSOR && !isnull(i_qei)){
        if(isnull(i_qei)){
            printstrln("Velocity Control Loop ERROR: Interface for QEI Service not provided");
        }else{
            qei_config = i_qei.getQEIConfig();
        }
    }

    motorcontrol_config = i_motorcontrol.getConfig();

    //Limits
    if(motorcontrol_config.motor_type == BLDC_MOTOR){
        velocity_control_out_limit = BLDC_PWM_CONTROL_LIMIT;
    }else if(motorcontrol_config.motor_type == BDC_MOTOR){
        velocity_control_out_limit = BDC_PWM_CONTROL_LIMIT;
    }

    if(velocity_control_config.Ki != 0)
        error_velocity_I_limit = velocity_control_out_limit * PID_DENOMINATOR / velocity_control_config.Ki;

    init_filter(filter_buffer, index, FILTER_SIZE_MAX);

    if (velocity_control_config.feedback_sensor == HALL_SENSOR){
         speed_factor_hall = hall_config.pole_pairs*4096*(velocity_control_config.control_loop_period)/1000; // variable pole_pairs
//       hall_crossover = hall_config.max_ticks - hall_config.max_ticks/10;
    }
    else if (velocity_control_config.feedback_sensor >= QEI_SENSOR){
         speed_factor_qei = (qei_config.ticks_resolution * QEI_CHANGES_PER_TICK ) * (velocity_control_config.control_loop_period)/1000;       // variable qei_real_max
         qei_crossover = (qei_config.ticks_resolution * QEI_CHANGES_PER_TICK ) - (qei_config.ticks_resolution * QEI_CHANGES_PER_TICK )/10;
    }

    printstrln("*************************************\n    VELOCITY CONTROLLER STARTING\n*************************************");

    t :> ts;
    init_state = INIT;

    while (1) {
//#pragma ordered
        select {
        case t when timerafter (ts +  USEC_STD * velocity_control_config.control_loop_period) :> ts:

            if (compute_flag == 1) {
                /* calculate actual velocity from hall/qei with filter*/
                if (velocity_control_config.feedback_sensor == HALL_SENSOR) {
                    if (init == 0) {
                        { position, direction } = i_hall.get_hall_position_absolute();//get_hall_position_absolute(c_hall);
                        if (position > 2049) {
                            init = 1;
                            previous_position = 2049;
                        } else if (position < -2049) {
                            init = 1;
                            previous_position = -2049;
                        }
                        raw_speed = 0;
                        //target_velocity = 0;
                    } else if (init == 1) {
                        { position, direction } = i_hall.get_hall_position_absolute();//get_hall_position_absolute(c_hall);
                        difference = position - previous_position;
                        if (difference > hall_crossover) {
                            difference = old_difference;
                        } else if (difference < -hall_crossover) {
                            difference = old_difference;
                        }
                        raw_speed = (difference*rpm_constant)/speed_factor_hall;
#ifdef Debug_velocity_ctrl
                        //xscope_int(RAW_SPEED, raw_speed);
#endif
                        previous_position = position;
                        old_difference = difference;
                    }
                } else if (velocity_control_config.feedback_sensor >= QEI_SENSOR) {
                    { position, direction } = i_qei.get_qei_position_absolute();
                    difference = position - previous_position;

                    if (difference > qei_crossover) {
                        difference = old_difference;
                    }

                    if (difference < -qei_crossover) {
                        difference = old_difference;
                    }

                    raw_speed = (difference*rpm_constant)/speed_factor_qei;

#ifdef Debug_velocity_ctrl
                    //xscope_int(RAW_SPEED, raw_speed);
#endif
                    previous_position = position;
                    old_difference = difference;
                }
                /**
                 * Or any other sensor interfaced to the IFM Module
                 * place client functions here to acquire velocity/position
                 */

                actual_velocity = filter(filter_buffer, index, filter_length, raw_speed);
            }

            if(activate == 1) {
#ifdef Debug_velocity_ctrl
                xscope_int(ACTUAL_VELOCITY, actual_velocity);
                xscope_int(TARGET_VELOCITY, target_velocity);
#endif
                compute_flag = 1;
                /* Controller */
                error_velocity   = (target_velocity - actual_velocity);
                error_velocity_I = error_velocity_I + error_velocity;
                error_velocity_D = error_velocity - previous_error;

                if (error_velocity_I > (error_velocity_I_limit)) {
                    error_velocity_I = (error_velocity_I_limit);
                } else if (error_velocity_I < -(error_velocity_I_limit)) {
                    error_velocity_I = 0 -(error_velocity_I_limit);
                }

                velocity_control_out = (velocity_control_config.Kp*error_velocity)  +
                                       (velocity_control_config.Ki*error_velocity_I) +
                                       (velocity_control_config.Kd*error_velocity_D);

                velocity_control_out /= PID_DENOMINATOR;

                if (velocity_control_out > velocity_control_out_limit) {
                    velocity_control_out = velocity_control_out_limit;
                } else if (velocity_control_out < -velocity_control_out_limit) {
                    velocity_control_out = -velocity_control_out_limit;
                }

                i_motorcontrol.setVoltage(velocity_control_out);//set_commutation_sinusoidal(c_commutation, velocity_control_out);//velocity_control_out

                previous_error = error_velocity;

            }
    //        printf("looping %d\n", velocity_control_config.Loop_time);
            break;

        case i_velocity_control[int i].set_velocity(int in_velocity):

            target_velocity = in_velocity;
            break;

        case i_velocity_control[int i].get_velocity()-> int out_velocity:

            out_velocity = actual_velocity;
            break;

        case i_velocity_control[int i].get_set_velocity() -> int out_set_velocity:

            out_set_velocity = target_velocity;
            break;

        case i_velocity_control[int i].set_velocity_ctrl_param(ControlConfig in_params):

            velocity_control_config.Kp = in_params.Kp;
            velocity_control_config.Ki = in_params.Ki;
            velocity_control_config.Kd = in_params.Kd;

            error_velocity_I_limit = 0;
            if(velocity_control_config.Ki != 0)
                error_velocity_I_limit = velocity_control_out_limit * PID_DENOMINATOR / velocity_control_config.Ki;

            break;

        case i_velocity_control[int i].set_velocity_filter(int in_length):

            filter_length = in_length;

            if(filter_length > FILTER_SIZE_MAX)
                filter_length = FILTER_SIZE_MAX;

            break;

        case i_velocity_control[int i].set_velocity_ctrl_hall_param(HallConfig in_config):

            hall_config.pole_pairs = in_config.pole_pairs;
            //hall_config.max_ticks = in_config.max_ticks;
            //hall_config.max_ticks_per_turn = in_config.max_ticks_per_turn;
            break;

        case i_velocity_control[int i].set_velocity_ctrl_qei_param(QEIConfig in_params):

            //qei_config.max_ticks = in_params.max_ticks;
            qei_config.index_type = in_params.index_type;
            qei_config.ticks_resolution = in_params.ticks_resolution;
            //qei_config.max_ticks_per_turn = in_params.max_ticks_per_turn;
            //qei_config.poles = in_params.poles;

            break;

        case i_velocity_control[int i].set_velocity_sensor(int in_sensor_used):

            velocity_control_config.feedback_sensor = in_sensor_used;

            if(in_sensor_used == HALL_SENSOR) {
                speed_factor_hall = hall_config.pole_pairs * 4096 * (velocity_control_config.control_loop_period)/1000;
                //hall_crossover = hall_config.max_ticks - hall_config.max_ticks/10;

            } else if(in_sensor_used >= QEI_SENSOR) {
                speed_factor_qei = qei_config.ticks_resolution * QEI_CHANGES_PER_TICK * (velocity_control_config.control_loop_period)/1000;
                qei_crossover = (qei_config.ticks_resolution * QEI_CHANGES_PER_TICK ) - (qei_config.ticks_resolution * QEI_CHANGES_PER_TICK )/10;
            }
            target_velocity = actual_velocity;
            break;


        case i_velocity_control[int i].shutdown_velocity_ctrl():

            activate = 0;
            error_velocity = 0;
            error_velocity_D = 0;
            error_velocity_I = 0;
            previous_error = 0;
            velocity_control_out = 0;
            i_motorcontrol.setVoltage(0); //set_commutation_sinusoidal(c_commutation, 0);
            i_motorcontrol.disableFets();//disable_motor(c_commutation);
            delay_milliseconds(30);//wait_ms(30, 1, t);
            break;

        case i_velocity_control[int i].check_velocity_ctrl_state() -> int out_state:

            out_state = activate;
            break;

        case i_velocity_control[int i].check_busy() -> int out_state:

                out_state = activate;
                break;

        case i_velocity_control[int i].enable_velocity_ctrl():

            activate = 1;
            while (1) {
                init_state = i_motorcontrol.checkBusy();//__check_commutation_init(c_commutation);
                if (init_state == INIT) {
#ifdef debug_print
                    printf("commutation intialized\n");
#endif
                    fet_state = i_motorcontrol.getFetsState();//check_fet_state(c_commutation);
                    if (fet_state == 1) {
                        i_motorcontrol.enableFets();//enable_motor(c_commutation);
                        delay_milliseconds(2);//wait_ms(2, 1, t);
                    }
                    break;
                }
            }

#ifdef debug_print
                printf("velocity control activated\n");
#endif
            break;

        case i_velocity_control[int i].get_velocity_control_config() -> ControlConfig out_config:

                out_config = velocity_control_config;
                break;

            }
           // break;
        }

}
