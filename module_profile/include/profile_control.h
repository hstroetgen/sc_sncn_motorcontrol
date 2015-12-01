/**
 * @file profile_control.h
 * @brief Profile Control functions
 *  Implements position profile control, velocity profile control
 *  and torque profile control functions
 * @author Synapticon GmbH <support@synapticon.com>
*/

#pragma once

#include <xs1.h>
#include <platform.h>
#include <position_ctrl_service.h>
#include <velocity_ctrl_service.h>
#include <torque_ctrl_service.h>


void init_position_profiler(int min_position, int max_position, int max_velocity, int max_acceleration,
                                interface PositionControlInterface client i_position_control);

void init_velocity_profiler(int max_velocity, int max_acceleration, int max_deceleration,
                                interface VelocityControlInterface client i_velocity_control);

/**
 * @brief Set profile position with Position Control loop
 *
 * @Output
 * @param c_position_ctrl for communicating with the Position Control Server
 *
 * @Input
 * @param target_position is the new target position in (ticks)
 * @param velocity in (rpm)
 * @param acceleration in (rpm/s)
 * @param deceleration in (rpm/s)
 *
 */
void set_profile_position( int target_position, int velocity, int acceleration, int deceleration,
                           interface PositionControlInterface client i_position_control );

/**
 * @brief Set profile velocity with Velocity Control loop
 *
 * @Output
 * @param c_velocity_ctrl for communicating with the Velocity Control Server
 *
 * @Input
 * @param target_velocity is the new target velocity in (rpm)
 * @param acceleration in (rpm/s)
 * @param deceleration in (rpm/s)
 * @param max_profile_velocity is max velocity for the profile in (rpm)
 *
 */
void set_profile_velocity( int target_velocity, int acceleration, int deceleration,
                           interface VelocityControlInterface client i_velocity_control );

/**
 * @brief Set profile torque with Torque Control loop
 *
 * @Output
 * @param c_torque_ctrl for communicating with the Torque Control Server
 *
 * @Input
 * @param target_torque is the new target torque in (mNm * current resolution)
 * @param torque_slope in (mNm/s * current resolution)
 * @param cst_params struct defines cyclic synchronous torque params
 *
 */
void set_profile_torque( int target_torque, int torque_slope,
                         cst_par & cst_params, interface TorqueControlInterface client i_torque_control );

