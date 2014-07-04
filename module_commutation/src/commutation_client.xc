/**
 * @file comm_loop_client.xc
 * @brief Commutation Loop Client functions
 * @author Pavan Kanajar <pkanajar@synapticon.com>
 * @author Ludwig Orgler <lorgler@synapticon.com>
 * @author Martin Schwarz <mschwarz@synapticon.com>
 */

#include <commutation_client.h>
#include <internal_config.h>

/* MAX Input value 13739 */
void set_commutation_sinusoidal(chanend c_commutation, int input_voltage)
{
    c_commutation <: SET_VOLTAGE;
    c_commutation <: input_voltage;
    return;
}

void set_commutation_params(chanend c_commutation, commutation_par &commutation_params)
{
    c_commutation <: SET_COMMUTATION_PARAMS;
    c_commutation :> commutation_params.angle_variance;
    c_commutation :> commutation_params.max_speed_reached;
    c_commutation :> commutation_params.hall_offset_clk;
    c_commutation :> commutation_params.hall_offset_cclk;
    c_commutation :> commutation_params.winding_type;
}

void set_commutation_sensor(chanend c_commutation, int sensor_select)
{
    c_commutation <: SENSOR_SELECT;
    c_commutation <: sensor_select;
    return;
}

int check_fet_state(chanend c_commutation)
{
    int state;
    c_commutation <: FETS_STATE;
    c_commutation :> state;
    return state;
}

void disable_motor(chanend c_commutation)
{
    c_commutation <: DISABLE_FETS;
    return;
}

void enable_motor(chanend c_commutation)
{
    c_commutation <: ENABLE_FETS;
    return;
}

