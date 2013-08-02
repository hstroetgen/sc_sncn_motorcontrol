/**
 * \file hall_server.h
 *
 *
 *	Hall Sensor Server
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and Synapticon GmbH.
 *
 * Copyright 2013, Synapticon GmbH & XMOS Ltd. All rights reserved.
 * Authors:  Martin Schwarz <mschwarz@synapticon.com> &  Ludwig Orgler <orgler@tin.it>
 *
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code arse still covered by the
 * copyright notice above.

 *
 **/

#pragma once

#include <xs1.h>
#include <dc_motor_config.h>



/** \brief A basic hall encoder server
 *
 *  This implements the basic hall sensor server
 *
 *	\param p_hall the port for reading the hall sensor data
 *	\param hall_params struct defines the pole-pairs and gear ratio
 *  \param c_hall_p1 the control channel for reading hall position in order of priority (highest) 1 ... (lowest) 4
 *  \param c_hall_p2 the control channel for reading hall position (priority 2)
 *  \param c_hall_p3 the control channel for reading hall position (priority 3)
 *  \param c_hall_p4 the control channel for reading hall position (priority 4)
 *
 */
void run_hall( port in p_hall, hall_par &hall_params, chanend c_hall_p1, chanend c_hall_p2, chanend c_hall_p3, chanend c_hall_p4);
