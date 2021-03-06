/**
 * @file hall_struct.h
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <position_feedback_common.h>

#define HALL_ERROR                   0
#define HALL_SUCCESS                 1

#define HALL_TICKS_PER_ELECTRICAL_ROTATION 4096

// Hall_states
#define HALL_STATE_0  4
#define HALL_STATE_1  6
#define HALL_STATE_2  2
#define HALL_STATE_3  3
#define HALL_STATE_4  1
#define HALL_STATE_5  5

// defined angle for each hall state
#define HALL_ANGLE_0 3755
#define HALL_ANGLE_1 341
#define HALL_ANGLE_2 1024
#define HALL_ANGLE_3 1707
#define HALL_ANGLE_4 2389
#define HALL_ANGLE_5 3072

// longest (acceptable) electrical period
#define HALL_PERIOD_MAX   1000000
#define HALL_TRANSITION_PERIOD_MAX HALL_PERIOD_MAX/6

#define HALL_FILTER_ORDER 3


/**
 * @brief Structure for Hall sensor configuration
 */
typedef struct {
    EncoderPortNumber port_number;  /**< To select which input port is used */
} HallConfig;


// variables related to hall measurement
typedef struct {
    int hall_sector;
    int hall_period;

    int hall_transition_period;
    int hall_last_transition_period;

    int hall_pin_state;

    int hall_next_state;
    int hall_previous_state;

    int hall_direction_of_rotation;

    int hall_angle;
    int hall_interpolated_angle;

    int hall_speed;
    int hall_speed_before_stopping;
    int hall_filtered_speed;

    unsigned int hall_transition_period_at_1rpm;

    unsigned int hall_f_clock;

    // filter constants
    int hall_filter_index_newest;
    int h[3];
    int hall_filter_buffer[3];
} hall_variables;

