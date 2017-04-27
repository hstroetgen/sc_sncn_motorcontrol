/**
 * @file hall_service.h
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once


#ifdef __XC__

#include <position_feedback_service.h>

/**
 *
 * @brief Service to read and process data from a Feedback Hall Sensor.
 *
 * @param qei_hall_port Input port for Hall signals.
 * @param gpio_ports GPIO ports array
 * @param position_feedback_config Configuration for the service.
 * @param i_shared_memory Client interface to write the position data to the shared memory.
 * @param i_position_feedback Server interface used by clients for configuration and direct position read.
 */
void hall_service(QEIHallPort &qei_hall_port, port * (&?gpio_ports)[4], PositionFeedbackConfig &position_feedback_config,
                  client interface shared_memory_interface ?i_shared_memory,
                  server interface PositionFeedbackInterface i_position_feedback[3]);

#endif
