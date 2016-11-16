/*
 * position_feedback_service.h
 *
 *  Created on: May 27, 2016
 *      Author: romuald
 */

#pragma once

#include <biss_config.h>
#include <contelec_config.h>
#include <ams_config.h>

#include <biss_struct.h>
#include <contelec_struct.h>
#include <ams_struct.h>
#include <hall_struct.h>
#include <qei_struct.h>

typedef struct {
    int sensor_type;
    int polarity;
    BISSConfig biss_config;
    CONTELECConfig contelec_config;
    AMSConfig ams_config;
    HallConfig hall_config;
    QEIConfig qei_config;
} PositionFeedbackConfig;


#ifdef __XC__

#include <spi_master.h>

interface PositionFeedbackInterface
{
    /**
     * @brief Notifies the interested parties that a new notification
     * is available.
     */
    [[notification]]
    slave void notification();

    /**
     * @brief Provides the type of notification currently available.
     *
     * @return type of the notification
     */
    [[clears_notification]]
    int get_notification();

    unsigned int get_angle(void);

    { int, unsigned int } get_position(void);

    { int, unsigned int, unsigned int } get_real_position(void);

    int get_velocity(void);

    unsigned int get_ticks_per_turn();

    PositionFeedbackConfig get_config(void);

    void set_config(PositionFeedbackConfig in_config);

    void set_position(int in_count);

    unsigned int set_angle(unsigned int in_angle);

    unsigned int send_command(int opcode, int data, int data_bits);

    void exit();
};

typedef struct {
    spi_master_interface spi_interface;
    port ?slave_select;
} SPIPorts;

typedef struct {
    port ?p_qei_config; /**< [Nullable] Port to control the signal input circuitry (if applicable in your SOMANET device). Also used for the BiSS clock output */
    port p_qei; /**< 4-bit Port for Encoder Interface signals input. Also used for BiSS data*/
} QEIPorts;

typedef struct {
    port ?p_hall;        /**< Port for Hall signals. */
} HallPorts;


#include <memory_manager.h>
#include <biss_service.h>
#include <contelec_service.h>
#include <ams_service.h>
#include <hall_service.h>
#include <qei_service.h>


void position_feedback_service(HallPorts &?hall_ports, QEIPorts &?biss_ports, SPIPorts &?spi_ports,
                               PositionFeedbackConfig &?position_feedback_config_1,
                               client interface shared_memory_interface ?i_shared_memory_1,
                               server interface PositionFeedbackInterface ?i_position_feedback_1[3],
                               PositionFeedbackConfig &?position_feedback_config_2,
                               client interface shared_memory_interface ?i_shared_memory_2,
                               server interface PositionFeedbackInterface ?i_position_feedback_2[3]);

#endif
