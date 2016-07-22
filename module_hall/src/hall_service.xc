/**
 * @file hall_server.xc
 * @brief Hall Sensor Server Implementation
 * @author Synapticon GmbH <support@synapticon.com>
*/
#include <xs1.h>
#include <hall_service.h>
#include <limits.h>
#include <filter_blocks.h>
#include <refclk.h>
#include <stdlib.h>
#include <print.h>

#include <mc_internal_constants.h>

int check_hall_config(HallConfig &hall_config){

    if (hall_config.pole_pairs < 1 || hall_config.pole_pairs > 11) {
        printstrln("hall_service: ERROR: Wrong Hall configuration: wrong pole-pairs");
        return ERROR;
    }

    return SUCCESS;
}

[[combinable]]
 void hall_service(PositionFeedbackPorts &position_feedback_ports, HallConfig & hall_config,
                   client interface shared_memory_interface ?i_shared_memory,
                   server interface PositionFeedbackInterface i_position_feedback[3])
{
    //Set freq to 250MHz (always needed for velocity calculation)
    write_sswitch_reg(get_local_tile_id(), 8, 1); // (8) = REFDIV_REGNUM // 500MHz / ((1) + 1) = 250MHz

    if (check_hall_config(hall_config) == ERROR) {
        printstrln("hall_service: ERROR: Error while checking the Hall sensor configuration");
        return;
    }

    printstr(">>   SOMANET HALL SENSOR SERVICE STARTING...\n");

    #define defPeriodMax 1000000  //1000msec
    timer tx, tmr;
    unsigned int ts;

    unsigned int angle1 = 0;            // newest angle (base angle on hall state transition)
    unsigned int delta_angle = 0;
    unsigned int angle = 0;

    unsigned int iCountMicroSeconds = 0;
    unsigned int iPeriodMicroSeconds = 0;
    unsigned int iTimeCountOneTransition = 0;
    unsigned int iTimeSaveOneTransition = 0;

    unsigned int pin_state = 0;         // newest hall state
    unsigned int pin_state_last = 0;
    unsigned int pin_state_monitor = 0;
    unsigned int new1 = 0;
    unsigned int new2 = 0;
    unsigned int uHallNext = 0;
    unsigned int uHallPrevious = 0;
    int xreadings = 0;

    int iHallError = 0;
    int direction = 0;

    int position = 0;
    int previous_position = 0;
    int count = 0;
    int first = 1;
    int time_elapsed = 0;
    int init_state = INIT;

    timer t1;
    int time1;
    int init_velocity = 0;

    int previous_position1 = 0;
    int velocity = 0;
    int difference1 = 0;
    int old_difference = 0;
    int filter_length = FILTER_LENGTH_HALL;
    int filter_buffer[FILTER_LENGTH_HALL] = {0};
    int index = 0;
    int raw_velocity = 0;
    int hall_crossover = (4096 * 9 )/10;
    int status = 0; //1 changed

    int config_max_ticks_per_turn = hall_config.pole_pairs * HALL_TICKS_PER_ELECTRICAL_ROTATION;
    int const config_hall_max_count = INT_MAX;
    int const config_hall_min_count = INT_MIN;

    int notification = MOTCTRL_NTF_EMPTY;

    /* Init hall sensor */
    position_feedback_ports.p_hall :> pin_state;
    pin_state &= 0x07;
    pin_state_monitor = pin_state;
    switch (pin_state) {
        case 3:
            angle = 0;
            break;
        case 2:
            angle = 682;
            break; //  60
        case 6:
            angle = 1365;
            break;
        case 4:
            angle = 2048;
            break; // 180
        case 5:
            angle = 2730;
            break;
        case 1:
            angle = 3413;
            break; // 300 degree
    }

    t1 :> time1;
    tmr :> ts;

    while (1) {
//#pragma xta endpoint "hall_loop"
      //[[ordered]] //FixMe ordered is not supported for combinable functions
        select {
            case i_position_feedback[int i].get_notification() -> int out_notification:

                out_notification = notification;
                break;

//            case i_position_feedback[int i].get_hall_pinstate_angle_velocity_position() -> {unsigned out_pinstate, int out_position, int out_velocity, int out_count}:
//
//                out_pinstate = pin_state_monitor;
//                out_position = angle;
//                out_velocity = raw_velocity;
//                out_count = count;
//                break;

//            case i_position_feedback[int i].get_hall_pinstate() -> unsigned out_pinstate:
//
//                out_pinstate = pin_state_monitor;
//                break;

            case i_position_feedback[int i].get_angle() -> unsigned int out_angle:

                out_angle = angle;
                break;

            case i_position_feedback[int i].get_position() -> { int out_count, unsigned int out_position }:

                out_count = count;
                out_position = angle;
                break;

            case i_position_feedback[int i].get_velocity() -> int out_velocity:

                out_velocity = raw_velocity;
                break;

            case i_position_feedback[int i].set_position(int in_count):

                count = in_count;
                break;

            case i_position_feedback[int i].get_config() -> PositionFeedbackConfig out_config:

                out_config.hall_config = hall_config;
                break;

            case i_position_feedback[int i].set_config(PositionFeedbackConfig in_config):

                hall_config = in_config.hall_config;
                config_max_ticks_per_turn = hall_config.pole_pairs * HALL_TICKS_PER_ELECTRICAL_ROTATION;
                status = 1;

                notification = MOTCTRL_NTF_CONFIG_CHANGED;
                // TODO: Use a constant for the number of interfaces
                for (int i = 0; i < 5; i++) {
                    i_position_feedback[i].notification();
                }
                break;

            case i_position_feedback[int i].get_ticks_per_turn() -> unsigned int out_ticks_per_turn:
                out_ticks_per_turn = HALL_TICKS_PER_ELECTRICAL_ROTATION;
                break;

            case i_position_feedback[int i].set_angle(unsigned int in_angle) -> unsigned int out_offset:
                break;

            case i_position_feedback[int i].get_real_position() -> { int out_count, unsigned int out_position,  unsigned int out_status}:
                break;

            case i_position_feedback[int i].send_command(int opcode, int data, int data_bits) -> unsigned int out_status:
                break;

            case tmr when timerafter(ts + PULL_PERIOD_USEC * USEC_FAST) :> ts: //12 usec 3000
                switch (xreadings) {
                    case 0:
                        position_feedback_ports.p_hall :> new1;
                        new1 &= 0x07;
                        xreadings++;
                        break;
                    case 1:
                        position_feedback_ports.p_hall :> new2;
                        new2 &= 0x07;
                        if (new2 == new1) {
                            xreadings++;
                        } else {
                            xreadings=0;
                        }
                        break;
                    case 2:
                        position_feedback_ports.p_hall :> new2;
                        new2 &= 0x07;
                        if (new2 == new1) {
                            pin_state = new2;
                        } else {
                            xreadings=0;
                        }
                        break;
                }//eof switch

                position_feedback_ports.p_hall :> pin_state_monitor;
                pin_state_monitor &= 0x07;

                iCountMicroSeconds = iCountMicroSeconds + PULL_PERIOD_USEC; // period in 12 usec
                iTimeCountOneTransition = iTimeCountOneTransition + PULL_PERIOD_USEC ;

                if (pin_state != pin_state_last) {
                    if(pin_state == uHallNext) {
                        direction = 1;
                    }

                    if (pin_state == uHallPrevious) {
                        direction =-1;
                    }

                    //if(direction >= 0) // CW  3 2 6 4 5 1

                    switch(pin_state) {
                        case 3:
                            angle1 = 0;
                            uHallNext = 2;
                            uHallPrevious = 1;
                            break;
                        case 2:
                            angle1 = 682;
                            uHallNext = 6;
                            uHallPrevious = 3;
                            break; //  60
                        case 6:
                            angle1 = 1365;
                            uHallNext = 4;
                            uHallPrevious = 2;
                            break;
                        case 4:
                            angle1 = 2048;
                            uHallNext = 5;
                            uHallPrevious = 6;
                            break; // 180
                        case 5:
                            angle1 = 2730;
                            uHallNext = 1;
                            uHallPrevious = 4;
                            break;
                        case 1:
                            angle1 = 3413;
                            uHallNext = 3;
                            uHallPrevious = 5;
                            break; // 300 degree
                        default:
                            iHallError++;
                            break;
                    }

                    if (direction == 1)
                        if (pin_state_last == 1 && pin_state == 3) {
                            // transition to NULL
                            iPeriodMicroSeconds = iCountMicroSeconds;
                            iCountMicroSeconds = 0;
                            if (iPeriodMicroSeconds) {
                                time_elapsed = iPeriodMicroSeconds;
                            }
                        }

                    if (direction == -1) {
                        if (pin_state_last == 3 && pin_state == 1) {
                            iPeriodMicroSeconds = iCountMicroSeconds;
                            iCountMicroSeconds = 0;
                            if (iPeriodMicroSeconds) {
                                time_elapsed = 0 - iPeriodMicroSeconds;
                            }
                        }
                    }

                    iTimeSaveOneTransition = iTimeCountOneTransition;
                    iTimeCountOneTransition = 0;
                    delta_angle = 0;
                    pin_state_last = pin_state;

                }// end (pin_state != pin_state_last


                if (iCountMicroSeconds > defPeriodMax) {
                    iCountMicroSeconds = defPeriodMax;
                }

                if (iTimeSaveOneTransition) {
                    delta_angle = (682 * iTimeCountOneTransition) / iTimeSaveOneTransition;
                }

                if (delta_angle >= 680) {
                    delta_angle = 680;
                }

                if (iTimeCountOneTransition > 50000) {
                    direction = 0;
                }

                angle = angle1;

                if (direction == 1) {
                    angle += delta_angle;
                }

                if (direction == -1) {
                    angle -= delta_angle;
                }

                angle &= 0x0FFF; // 4095

                if (first == 1) {
                    previous_position = angle;
                    first = 0;
                }

                if (previous_position != angle) {
                    position = angle;
                    if (position - previous_position <= -1800) {
                        count = count + (4095 + position - previous_position);
                    } else if (position - previous_position >= 1800) {
                        count = count + (-4095 + position - previous_position);
                    } else {
                        count = count + position - previous_position;
                    }
                    previous_position = angle;
                }

                if (count > config_hall_max_count || count < config_hall_min_count) {
                    count = 0;
                }

                if (status == 1) {
                     status = 0;
                }

                if (!isnull(i_shared_memory)) {
                    if (hall_config.enable_push_service == PushAll) {
                        i_shared_memory.write_angle_velocity_position(angle, raw_velocity, count);
                    } else if (hall_config.enable_push_service == PushAngle) {
                        i_shared_memory.write_angle_electrical(angle);
                    } else if (hall_config.enable_push_service == PushPosition) {
                        i_shared_memory.write_velocity_position(raw_velocity, count);
                    }
                }

                break;

            case tx when timerafter(time1 + MSEC_FAST) :> time1:
                if (init_velocity == 0) {
                    if (count > 2049) {
                        init_velocity = 1;
                        previous_position1 = 2049;
                    } else if (count < -2049) {
                        init_velocity = 1;
                        previous_position1 = -2049;
                    }
                    velocity = 0;
                } else {
                    difference1 = count - previous_position1;
                    if (difference1 > hall_crossover) {
                        difference1 = old_difference;
                    } else if (difference1 < -hall_crossover) {
                        difference1 = old_difference;
                    }
                    velocity = difference1;
                    previous_position1 = count;
                    old_difference = difference1;
                }
                //FIXME check if the velocity computation is disturbing the position measurement
//                raw_velocity = _modified_internal_filter(filter_buffer, index, filter_length, velocity);
                raw_velocity = filter(filter_buffer, index, filter_length, velocity);
                // velocity in rpm = ( difference ticks * (1 minute / 1 ms) ) / ticks per turn
                //                 = ( difference ticks * (60,000 ms / 1 ms) ) / ticks per turn
                raw_velocity = (raw_velocity * 60000 ) / config_max_ticks_per_turn;
                break;

        }
//#pragma xta endpoint "hall_loop_stop"
    }
}

