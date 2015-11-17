/**
 * @file hall_server.h
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <xs1.h>
#include <hall_config.h>

/**
* @brief Structure containing hall sensor port/s
*/
typedef struct {
    port p_hall;
} HallPorts;

/**
 * @brief initialize hall sensor
 *
 * @param hall_params struct defines the pole-pairs and gear ratio
 */
void init_hall_param(hall_par & hall_params);

/**
 * @brief A basic hall sensor server
 *
 * @param[out] c_hall_p1 the control channel for reading hall position in order of priority (highest) 1 ... (lowest) 6
 * @param[out] c_hall_p2 the control channel for reading hall position (priority 2)
 * @param[out] c_hall_p3 the control channel for reading hall position (priority 3)
 * @param[out] c_hall_p4 the control channel for reading hall position (priority 4)
 * @param[out] c_hall_p5 the control channel for reading hall position (priority 5)
 * @param[out] c_hall_p6 the control channel for reading hall position (priority 6)
 * @param[in] hall_ports structure containing the ports for reading the hall sensor data
 * @param hall_params structure defines the pole-pairs and gear ratio
 */
[[combinable]]
void run_hall(chanend ? c_hall_p1, chanend ? c_hall_p2, chanend ? c_hall_p3, chanend ? c_hall_p4,
              chanend ? c_hall_p5, chanend ? c_hall_p6, HallPorts & hall_ports, hall_par & hall_params);
