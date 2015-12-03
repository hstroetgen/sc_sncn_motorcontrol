/**
 * @file  position_ctrl_server.h
 * @brief Position Control Loop Server Implementation
 * @author Synapticon GmbH <support@synapticon.com>
*/

#pragma once

#include <control_loops_common.h>
#include <qei_service.h>
#include "control_loops_common.h"
#include <commutation_service.h>

#include <internal_config.h>

interface PositionControlInterface{

    int check_busy();
    void set_position(int target_position);
    int get_position();
    void set_position_ctrl_param(ControlConfig position_ctrl_params);
    void set_position_ctrl_hall_param(HallConfig hall_config);
    void set_position_ctrl_qei_param(QEIConfig qei_params);
    void set_position_sensor(int sensor_used);
    void enable_position_ctrl();
    void shutdown_position_ctrl();
    int check_position_ctrl_state();
    ControlConfig getControlConfig();
    HallConfig getHallConfig();
    QEIConfig getQEIConfig();
};

/**
 * @brief Initialise Position Control Loop
 *
 * @Input Channel
 * @param c_position_ctrl channel to signal initialisation
 */
int init_position_control(interface PositionControlInterface client i_position_control);

/**
 * @brief Position Limiter
 *
 * @Input
 * @param position is the input position to be limited in range
 * @param max_position_limit is the max position that can be reached
 * @param min_position_limit is the min position that can be reached
 *
 * @Output
 * @return position in the range [min_position_limit - max_position_limit]
 */
int position_limit(int position, int max_position_limit, int min_position_limit);

/**
 * @brief Set new target position for position control (advanced function)
 *
 * @Input Channel
 * @param c_position_ctrl channel to signal new target position
 *
 * @Input
 * @param csp_param struct defines the motor parameters and position limits
 * @param target_position is the new target position
 * @param position_offset defines offset in position
 * @param velocity_offset defines offset in velocity
 * @param torque_offset defines offset in torque
 */
void set_position_csp(csp_par & csp_params, int target_position, int position_offset, int velocity_offset,
                      int torque_offset, interface PositionControlInterface client i_position_control);


/**
 * @brief Position Control Loop
 *  Implements PID controller for position using Hall or QEI sensors.
 *  Note: The Server must be placed on CORES 0/1/2 only.
 *
 * @Input
 * @param position_ctrl_params struct defines the position control parameters
 * @param hall_params struct defines the poles for hall sensor and gear-ratio
 * @param qei_params struct defines the resolution for qei sensor and gear-ratio
 * @param sensor_used specify the sensors to used via HALL/QEI defines
 *
 * @Input Channel
 * @param c_hall channel to receive position information from hall
 * @param c_qei channel to receive position information from qei
 * @param c_position_ctrl channel to receive/send position control information
 *
 * @Output Channel
 * @param c_commutation channel to send motor voltage input value
 *
 */
void position_control_service(ControlConfig & position_ctrl_params,
                    interface HallInterface client ?i_hall,
                    interface QEIInterface client ?i_qei,
                    interface PositionControlInterface server i_position_control,
                    interface CommutationInterface client commutation_interface);

