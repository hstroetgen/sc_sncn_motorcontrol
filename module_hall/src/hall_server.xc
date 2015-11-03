/**
 * @file hall_server.xc
 * @brief Hall Sensor Server Implementation
 * @author Synapticon GmbH <support@synapticon.com>
*/

#include <hall_config.h>
#include <filter_blocks.h>
#include <refclk.h>
#include <stdlib.h>
#include <stdint.h>
#include <refclk.h>
#include <stdio.h>

//TODO remove these dependencies
#include <bldc_motor_config.h>
//#pragma xta command "analyze loop hall_loop"
//#pragma xta command "set required - 10.0 us"
//#define DEBUG
/*
static select on_client_request(chanend ? c_client, int angle, int raw_velocity,
                                int init_state, int & count, int direction,
                                hall_par & hall_params, int & status, unsigned int raw_pin_states)
{
case !isnull(c_client) => c_client :> int command:
    switch (command) {
    case HALL_POS_REQ:
        c_client <: angle;
        break;

    case HALL_VELOCITY_REQ:
        c_client <: raw_velocity;
        break;

    case HALL_ABSOLUTE_POS_REQ:
        c_client <: count;
        c_client <: direction;
        break;

    case CHECK_BUSY:
        c_client <: init_state;
        break;

    case SET_HALL_PARAM_ECAT:
        c_client :> hall_params.pole_pairs;
        c_client :> hall_params.max_ticks;
        c_client :> hall_params.max_ticks_per_turn;
        status = 1;
        break;

    case HALL_RESET_COUNT_REQ:
        c_client :> count;
        break;

    case HALL_FILTER_PARAM_REQ:
        c_client <: hall_params.max_ticks_per_turn;
        break;

    case HALL_REQUEST_PORT_STATES:
        c_client <: raw_pin_states;
        break;

    default:
        break;
    }
    break;
}
*/
//FIXME rename to check_hall_parameters();
void init_hall_param(hall_par &hall_params)
{
    hall_params.pole_pairs = POLE_PAIRS;

    // Find absolute maximum position deviation from origin
    hall_params.max_ticks = (abs(MAX_POSITION_LIMIT) > abs(MIN_POSITION_LIMIT)) ? abs(MAX_POSITION_LIMIT) : abs(MIN_POSITION_LIMIT);

    hall_params.max_ticks_per_turn = POLE_PAIRS * HALL_POSITION_INTERPOLATED_RANGE;
    hall_params.max_ticks += hall_params.max_ticks_per_turn ;  // tolerance
    hall_params.sensor_polarity = POLARITY;

    return;
}

[[combinable]]
void run_hall(chanend ? c_hall_p1, chanend ? c_hall_p2, chanend ? c_hall_p3, chanend ? c_hall_p4,
              chanend ? c_hall_p5, chanend ? c_hall_p6, in port p_hall, hall_par & hall_params)
{
    init_hall_param(hall_params);

    printf("*************************************\n    HALL SENSOR SERVER STARTING\n*************************************\n");

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
    int hall_max_count = hall_params.max_ticks;
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

    /* Init hall sensor */
    p_hall :> pin_state;
    pin_state &= 0x07;
    pin_state_monitor = pin_state;
    switch(pin_state) {
    case 3: angle = 0;
        break;
    case 2: angle = 682;
        break; //  60
    case 6: angle = 1365;
        break;
    case 4: angle = 2048;
        break; // 180
    case 5: angle = 2730;
        break;
    case 1: angle = 3413;
        break; // 300 degree
    }

    t1 :> time1;
    tmr :> ts;


    while(1) {
//#pragma xta endpoint "hall_loop"
      //[[ordered]] //FixMe ordered is not supported for combinable functions
        select {
            case !isnull(c_hall_p1) => c_hall_p1 :> int command:
                switch (command) {
                case HALL_POS_REQ:
                    c_hall_p1 <: angle;
                    break;

                case HALL_VELOCITY_REQ:
                    c_hall_p1 <: raw_velocity;
                    break;

                case HALL_ABSOLUTE_POS_REQ:
                    c_hall_p1 <: count;
                    c_hall_p1 <: direction;
                    break;

                case CHECK_BUSY:
                    c_hall_p1 <: init_state;
                    break;

                case SET_HALL_PARAM_ECAT:
                    c_hall_p1 :> hall_params.pole_pairs;
                    c_hall_p1 :> hall_params.max_ticks;
                    c_hall_p1 :> hall_params.max_ticks_per_turn;
                    status = 1;
                    break;

                case HALL_RESET_COUNT_REQ:
                    c_hall_p1 :> count;
                    break;

                case HALL_FILTER_PARAM_REQ:
                    c_hall_p1 <: hall_params.max_ticks_per_turn;
                    break;

                case HALL_REQUEST_PORT_STATES:
                    c_hall_p1 <: pin_state_monitor;
                    break;

                default:
                    break;
                }
                break;

            case !isnull(c_hall_p2) => c_hall_p2 :> int command:
                switch (command) {
                case HALL_POS_REQ:
                    c_hall_p2 <: angle;
                    break;

                case HALL_VELOCITY_REQ:
                    c_hall_p2 <: raw_velocity;
                    break;

                case HALL_ABSOLUTE_POS_REQ:
                    c_hall_p2 <: count;
                    c_hall_p2 <: direction;
                    break;

                case CHECK_BUSY:
                    c_hall_p2 <: init_state;
                    break;

                case SET_HALL_PARAM_ECAT:
                    c_hall_p2 :> hall_params.pole_pairs;
                    c_hall_p2 :> hall_params.max_ticks;
                    c_hall_p2 :> hall_params.max_ticks_per_turn;
                    status = 1;
                    break;

                case HALL_RESET_COUNT_REQ:
                    c_hall_p2 :> count;
                    break;

                case HALL_FILTER_PARAM_REQ:
                    c_hall_p2 <: hall_params.max_ticks_per_turn;
                    break;

                case HALL_REQUEST_PORT_STATES:
                    c_hall_p2 <: pin_state_monitor;
                    break;

                default:
                    break;
                }
                break;

            case !isnull(c_hall_p3) => c_hall_p3 :> int command:
                switch (command) {
                case HALL_POS_REQ:
                    c_hall_p3 <: angle;
                    break;

                case HALL_VELOCITY_REQ:
                    c_hall_p3 <: raw_velocity;
                    break;

                case HALL_ABSOLUTE_POS_REQ:
                    c_hall_p3 <: count;
                    c_hall_p3 <: direction;
                    break;

                case CHECK_BUSY:
                    c_hall_p3 <: init_state;
                    break;

                case SET_HALL_PARAM_ECAT:
                    c_hall_p3 :> hall_params.pole_pairs;
                    c_hall_p3 :> hall_params.max_ticks;
                    c_hall_p3 :> hall_params.max_ticks_per_turn;
                    status = 1;
                    break;

                case HALL_RESET_COUNT_REQ:
                    c_hall_p3 :> count;
                    break;

                case HALL_FILTER_PARAM_REQ:
                    c_hall_p3 <: hall_params.max_ticks_per_turn;
                    break;

                case HALL_REQUEST_PORT_STATES:
                    c_hall_p3 <: pin_state_monitor;
                    break;

                default:
                    break;
                }
                break;

            case !isnull(c_hall_p4) => c_hall_p4 :> int command:
                switch (command) {
                case HALL_POS_REQ:
                    c_hall_p4 <: angle;
                    break;

                case HALL_VELOCITY_REQ:
                    c_hall_p4 <: raw_velocity;
                    break;

                case HALL_ABSOLUTE_POS_REQ:
                    c_hall_p4 <: count;
                    c_hall_p4 <: direction;
                    break;

                case CHECK_BUSY:
                    c_hall_p4 <: init_state;
                    break;

                case SET_HALL_PARAM_ECAT:
                    c_hall_p4 :> hall_params.pole_pairs;
                    c_hall_p4 :> hall_params.max_ticks;
                    c_hall_p4 :> hall_params.max_ticks_per_turn;
                    status = 1;
                    break;

                case HALL_RESET_COUNT_REQ:
                    c_hall_p4 :> count;
                    break;

                case HALL_FILTER_PARAM_REQ:
                    c_hall_p4 <: hall_params.max_ticks_per_turn;
                    break;

                case HALL_REQUEST_PORT_STATES:
                    c_hall_p4 <: pin_state_monitor;
                    break;

                default:
                    break;
                }
                break;

            case !isnull(c_hall_p5) => c_hall_p5 :> int command:
                switch (command) {
                case HALL_POS_REQ:
                    c_hall_p5 <: angle;
                    break;

                case HALL_VELOCITY_REQ:
                    c_hall_p5 <: raw_velocity;
                    break;

                case HALL_ABSOLUTE_POS_REQ:
                    c_hall_p5 <: count;
                    c_hall_p5 <: direction;
                    break;

                case CHECK_BUSY:
                    c_hall_p5 <: init_state;
                    break;

                case SET_HALL_PARAM_ECAT:
                    c_hall_p5 :> hall_params.pole_pairs;
                    c_hall_p5 :> hall_params.max_ticks;
                    c_hall_p5 :> hall_params.max_ticks_per_turn;
                    status = 1;
                    break;

                case HALL_RESET_COUNT_REQ:
                    c_hall_p5 :> count;
                    break;

                case HALL_FILTER_PARAM_REQ:
                    c_hall_p5 <: hall_params.max_ticks_per_turn;
                    break;

                case HALL_REQUEST_PORT_STATES:
                    c_hall_p5 <: pin_state_monitor;
                    break;

                default:
                    break;
                }
                break;

            case !isnull(c_hall_p6) => c_hall_p6 :> int command:
                switch (command) {
                case HALL_POS_REQ:
                    c_hall_p6 <: angle;
                    break;

                case HALL_VELOCITY_REQ:
                    c_hall_p6 <: raw_velocity;
                    break;

                case HALL_ABSOLUTE_POS_REQ:
                    c_hall_p6 <: count;
                    c_hall_p6 <: direction;
                    break;

                case CHECK_BUSY:
                    c_hall_p6 <: init_state;
                    break;

                case SET_HALL_PARAM_ECAT:
                    c_hall_p6 :> hall_params.pole_pairs;
                    c_hall_p6 :> hall_params.max_ticks;
                    c_hall_p6 :> hall_params.max_ticks_per_turn;
                    status = 1;
                    break;

                case HALL_RESET_COUNT_REQ:
                    c_hall_p6 :> count;
                    break;

                case HALL_FILTER_PARAM_REQ:
                    c_hall_p6 <: hall_params.max_ticks_per_turn;
                    break;

                case HALL_REQUEST_PORT_STATES:
                    c_hall_p6 <: pin_state_monitor;
                    break;

                default:
                    break;
                }
                break;

            case tmr when timerafter(ts + PULL_PERIOD_USEC*250) :> ts: //12 usec 3000
                switch(xreadings) {
                    case 0:
                        p_hall :> new1;
                        new1 &= 0x07;
                        xreadings++;
                        break;
                    case 1:
                        p_hall :> new2;
                        new2 &= 0x07;
                        if (new2 == new1) {
                            xreadings++;
                        } else {
                            xreadings=0;
                        }
                        break;
                    case 2:
                        p_hall :> new2;
                        new2 &= 0x07;
                        if (new2 == new1) {
                            pin_state = new2;
                        } else {
                            xreadings=0;
                        }
                        break;
                }//eof switch

                p_hall :> pin_state_monitor;
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
                        uHallNext=2;
                        uHallPrevious=1;
                        break;
                    case 2:
                        angle1 = 682;
                        uHallNext=6;
                        uHallPrevious=3;
                        break; //  60
                    case 6:
                        angle1 = 1365;
                        uHallNext=4;
                        uHallPrevious=2;
                        break;
                    case 4:
                        angle1 = 2048;
                        uHallNext=5;
                        uHallPrevious=6;
                        break; // 180
                    case 5:
                        angle1 = 2730;
                        uHallNext=1;
                        uHallPrevious=4;
                        break;
                    case 1:
                        angle1 = 3413;
                        uHallNext=3;
                        uHallPrevious=5;
                        break; // 300 degree
                    default:
                        iHallError++;
                        break;
                    }

                    if (direction == 1)
                        if (pin_state_last==1 && pin_state==3) {
                            // transition to NULL
                            iPeriodMicroSeconds = iCountMicroSeconds;
                            iCountMicroSeconds = 0;
                            if (iPeriodMicroSeconds) {
                                time_elapsed = iPeriodMicroSeconds;
                            }
                        }

                    if (direction == -1) {
                        if (pin_state_last==3 && pin_state==1) {
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
                    delta_angle = (682 *iTimeCountOneTransition)/iTimeSaveOneTransition;
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

                if (count > hall_max_count || count < -hall_max_count) {
                    count = 0;
                }

                if (status == 1) {
                     hall_max_count = hall_params.max_ticks;
                     status = 0;
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
                raw_velocity = _modified_internal_filter(filter_buffer, index, filter_length, velocity);
                break;

        }

//#pragma xta endpoint "hall_loop_stop"
    }
}

