/*
 * ecat_motor_drive.xc
 *
 *  Created on: Sep 13, 2013
 *      Author: pkanajar
 */
#include <ecat_motor_drive.h>
#include <xscope.h>

void xscope_initialise()
{
	{
		xscope_register(2, XSCOPE_CONTINUOUS, "0 actual_velocity", XSCOPE_INT,	"n",
							XSCOPE_CONTINUOUS, "1 target_velocity", XSCOPE_INT, "n");

		xscope_config_io(XSCOPE_IO_BASIC);
	}
	return;
}

void ecat_motor_drive(chanend pdo_out, chanend pdo_in, chanend coe_out, chanend c_signal, chanend c_hall_p4,\
		chanend c_qei_p4, chanend c_adc, chanend c_torque_ctrl, chanend c_velocity_ctrl, chanend c_position_ctrl)
{
	int i = 0;
	int mode=40;
	int core_id = 0;
	int steps;

	int target_velocity;
	int actual_velocity = 0;
	int target_position;
	int actual_position = 0;

	int position_ramp = 0;
	int prev_position = 0;

	int velocity_ramp = 0;
	int prev_velocity = 0;
	timer t;

	int init = 0;
	int op_set_flag = 0;
	int op_mode = 0;

	csv_par 	csv_params;
	ctrl_par 	velocity_ctrl_params;
	qei_par 	qei_params;
	hall_par 	hall_params;
	ctrl_par	position_ctrl_params;
	csp_par 	csp_params;
	pp_par 		pp_params;
	pv_par		pv_params;

	ctrl_proto_values_t InOut;
	int setup_loop_flag = 0;
	int sense;

	int ack = 0;
	int quick_active = 0;
	int mode_quick_flag = 0;
	int shutdown_ack = 0;
	int sensor_select;

	unsigned int time;
	int state;
	int statusword;
	int controlword;

	int mode_selected = 0;
	check_list checklist;

	state 		= init_state(); 			//init state
	checklist 	= init_checklist();
	InOut 		= init_ctrl_proto();

	/*init_csv_param(csv_params);
	init_csp_param(csp_params);
	init_hall_param(hall_params);
	init_pp_params(pp_params);
	init_pv_params(pv_params);
	init_qei_param(qei_params);*/

//#ifdef ENABLE_xscope_main
 //xscope_initialise();
//#endif
	t:>time;
	while(1)
	{
		ctrlproto_protocol_handler_function(pdo_out, pdo_in, InOut);


		controlword = InOut.control_word;
		update_checklist(checklist, mode, c_signal, c_hall_p4, c_qei_p4, c_adc, c_torque_ctrl, c_velocity_ctrl, c_position_ctrl);

		state = get_next_state(state, checklist, controlword);
		statusword = update_statusword(statusword, state, ack, quick_active, shutdown_ack);
		InOut.status_word = statusword;


		if(setup_loop_flag == 0)
		{
			if(controlword == 6)
			{
				update_hall_param_ecat(hall_params, coe_out);
				update_qei_param_ecat(qei_params, coe_out);
				sensor_select = sensor_select_sdo(coe_out);

				set_commutation_param_ecat(c_signal, hall_params);
				set_hall_param_ecat(c_hall_p4, hall_params);
				set_qei_param_ecat(c_qei_p4, qei_params);

				setup_loop_flag = 1;
			}
		}//*/
		if(mode_selected == 0)
		{
			switch(InOut.operation_mode)
			{
				case PP:
					if(op_set_flag == 0)
					{
						init = init_position_control(c_position_ctrl);
					}
					if(init == INIT)
					{
						op_set_flag = 1;
						enable_position_ctrl(c_position_ctrl);
						mode_selected = 1;
						op_mode = PP;
						steps = 0;
						mode_quick_flag = 10;
						ack = 0;
						shutdown_ack = 0;

						update_position_ctrl_param_ecat(position_ctrl_params, coe_out);
						sensor_select = sensor_select_sdo(coe_out);
						update_pp_param_ecat(pp_params, coe_out);
//
//						printintln(qei_params.gear_ratio);
//						printintln(qei_params.index);
//						printintln(qei_params.max_count);
//						printintln(qei_params.real_counts);
//						printintln(pp_params.base.max_profile_velocity);
//						printintln(pp_params.profile_velocity);
//						printintln(pp_params.base.profile_acceleration);
//						printintln(pp_params.base.profile_deceleration);
//						printintln(pp_params.base.quick_stop_deceleration);
//						printintln(pp_params.software_position_limit_max);
//						printintln(pp_params.software_position_limit_min);
//						printintln(pp_params.base.polarity);
//						printintln(pp_params.max_acceleration);

						if(sensor_select == HALL)
						{
							update_hall_param_ecat(hall_params, coe_out);
							init_position_ctrl_hall(hall_params, c_position_ctrl);
						}
						else if(sensor_select == QEI_INDEX || sensor_select == QEI_NO_INDEX)
						{
							update_qei_param_ecat(qei_params, coe_out);
							init_position_ctrl_qei(qei_params, c_position_ctrl);
						}

						init_position_ctrl_param_ecat(position_ctrl_params, c_position_ctrl);
						init_position_sensor_ecat(sensor_select, c_position_ctrl);//*/

						init_position_profile_limits(qei_params.gear_ratio, pp_params.max_acceleration, pp_params.base.max_profile_velocity);
						InOut.operation_mode_display = PP;
					}
					break;

				case PV:
					//printstrln("pv");
					if(op_set_flag == 0)
					{
						init = init_velocity_control(c_velocity_ctrl);
					}
					if(init == INIT)
					{
						op_set_flag = 1;
						enable_velocity_ctrl(c_velocity_ctrl);
						mode_selected = 1;
						op_mode = PV;
						steps = 0;
						mode_quick_flag = 10;
						ack = 0;
						shutdown_ack = 0;

						update_velocity_ctrl_param_ecat(velocity_ctrl_params, coe_out);  //after checking init go to set display mode
						sensor_select = sensor_select_sdo(coe_out);
						update_pv_param_ecat(pv_params, coe_out);

//						printintln(pv_params.max_profile_velocity);
//						printintln(pv_params.profile_acceleration);
//						printintln(pv_params.profile_deceleration);
//						printintln(pv_params.quick_stop_deceleration);
//						printintln(pv_params.polarity);

						if(sensor_select == HALL)
						{
							update_hall_param_ecat(hall_params, coe_out);
							init_velocity_ctrl_hall(hall_params, c_velocity_ctrl);
						}
						else if(sensor_select == QEI_INDEX || sensor_select == QEI_NO_INDEX)
						{
							update_qei_param_ecat(qei_params, coe_out);
							init_velocity_ctrl_qei(qei_params, c_velocity_ctrl);
						}

						init_velocity_ctrl_param_ecat(velocity_ctrl_params, c_velocity_ctrl);
						init_velocity_sensor_ecat(sensor_select, c_velocity_ctrl); //*/

						InOut.operation_mode_display = PV;
					}
					break;

				case CSP:
					if(op_set_flag == 0)
					{
						init = init_position_control(c_position_ctrl);
					}
					if(init == INIT)
					{
						op_set_flag = 1;
						enable_position_ctrl(c_position_ctrl);
						mode_selected = 1;
						mode_quick_flag = 10;
						op_mode = CSP;
						ack = 0;
						shutdown_ack = 0;

						update_position_ctrl_param_ecat(position_ctrl_params, coe_out);
						sensor_select = sensor_select_sdo(coe_out);
						update_csp_param_ecat(csp_params, coe_out);

						if(sensor_select == HALL)
						{
							update_hall_param_ecat(hall_params, coe_out);
							init_position_ctrl_hall(hall_params, c_position_ctrl);
						}
						else if(sensor_select == QEI_INDEX || sensor_select == QEI_NO_INDEX)
						{
							update_qei_param_ecat(qei_params, coe_out);
							init_position_ctrl_qei(qei_params, c_position_ctrl);
						}

						init_position_ctrl_param_ecat(position_ctrl_params, c_position_ctrl);
						init_position_sensor_ecat(sensor_select, c_position_ctrl);//*/

						InOut.operation_mode_display = CSP;
					}
					break;

				case CSV: 	//csv mode index
					if(op_set_flag == 0)
					{
						init = init_velocity_control(c_velocity_ctrl);

					}
					if(init == 1)
					{
						op_set_flag = 1;
						enable_velocity_ctrl(c_velocity_ctrl);
						mode_selected = 1;
						mode_quick_flag = 10;
						op_mode = CSV;
						ack = 0;
						shutdown_ack = 0;
						update_velocity_ctrl_param_ecat(velocity_ctrl_params, coe_out);  //after checking init go to set display mode
						sensor_select = sensor_select_sdo(coe_out);
						update_csv_param_ecat(csv_params, coe_out);

						if(sensor_select == HALL)
						{
							update_hall_param_ecat(hall_params, coe_out);
							init_velocity_ctrl_hall(hall_params, c_velocity_ctrl);
						}
						else if(sensor_select == QEI_INDEX || sensor_select == QEI_NO_INDEX)
						{
							update_qei_param_ecat(qei_params, coe_out);
							init_velocity_ctrl_qei(qei_params, c_velocity_ctrl);
						}

						init_velocity_ctrl_param_ecat(velocity_ctrl_params, c_velocity_ctrl);
						init_velocity_sensor_ecat(sensor_select, c_velocity_ctrl);
//*/
						InOut.operation_mode_display = CSV;
					}
					break;

			}
		}
//	    printhexln(InOut.control_word);
//	    printstr("mode ");
//	    printhexln(mode_selected);
//  	printstr("shtudown ");printhexln(shutdown_ack);
//		printstr("qactive ");printhexln(quick_active);
		if(mode_selected == 1)
		{
			switch(InOut.control_word)
			{
				case 0x000b: //quick stop
					if(op_mode == CSV || op_mode == PV)
					{
						actual_velocity = get_velocity(c_velocity_ctrl);
						if(op_mode == CSV)
							steps = init_quick_stop_velocity_profile(actual_velocity, csv_params.max_acceleration);//default acc
						else if(op_mode == PV)
							steps = init_quick_stop_velocity_profile(actual_velocity, pv_params.quick_stop_deceleration);
						i = 0;
						mode_selected = 3;// non interruptible mode
						mode_quick_flag = 0;
					}
					else if(op_mode == CSP || op_mode == PP)
					{
						actual_velocity = get_hall_speed(c_hall_p4, hall_params);
						actual_position = get_position(c_position_ctrl);

						if(!(actual_velocity<40 && actual_velocity>-40))
						{
							if(actual_velocity < 0)
							{
								actual_velocity = 0-actual_velocity;
								sense = -1;
							}
							if(op_mode == CSP)
								steps = init_quick_stop_position_profile( (actual_velocity*360)/(60*hall_params.gear_ratio), actual_position, csp_params.base.max_acceleration);
							else if(op_mode == PP)
								steps = init_quick_stop_position_profile( (actual_velocity*360)/(60*hall_params.gear_ratio), actual_position, pp_params.base.quick_stop_deceleration);
							i = 0;
							mode_selected = 3;// non interruptible mode
							mode_quick_flag = 0;
						}
						else
						{
							mode_selected = 100;
							op_set_flag = 0; init = 0;
							mode_quick_flag = 0;
						}
					}
					break;

				case 0x000f: //switch on cyclic
					//printstrln("cyclic");
					if(op_mode == CSV)
					{
						target_velocity = get_target_velocity(InOut);
						set_velocity_csv(csv_params, target_velocity, 0, 0, c_velocity_ctrl);

						actual_velocity = get_velocity(c_velocity_ctrl) *  csv_params.polarity;
						send_actual_velocity(actual_velocity, InOut);
					}
					else if(op_mode == CSP)
					{
						target_position = get_target_position(InOut);
						set_position_csp(csp_params, target_position, 0, 0, 0, c_position_ctrl);


						actual_position = get_position(c_position_ctrl) * csp_params.base.polarity;
						send_actual_position(actual_position, InOut);
//#ifdef ENABLE_xscope_main
	//					xscope_probe_data(0, actual_position);
	//					xscope_probe_data(1, target_position);
//#endif
					}
					else if(op_mode == PP)
					{
						if(ack == 1)
						{
							target_position = get_target_position(InOut);
							//printstr("tar pos ");printintln(target_position);
							actual_position = get_position(c_position_ctrl)*pp_params.base.polarity;
							send_actual_position(actual_position, InOut);

							if(prev_position != target_position)
							{
								ack = 0;
								steps = init_position_profile(target_position, actual_position, \
										pp_params.profile_velocity, pp_params.base.profile_acceleration,\
										pp_params.base.profile_deceleration);
								//printstr("steps ");printintln(steps);
								i = 1;
								prev_position = target_position;
							}
						}
						else if(ack == 0)
						{
							if(i < steps)
							{
								position_ramp = position_profile_generate(i);
								set_position( position_limit( position_ramp * pp_params.base.polarity ,	\
										pp_params.software_position_limit_max * 10000  , 			\
										pp_params.software_position_limit_min * 10000) , c_position_ctrl);
								i++;
							}
							else if(i >= steps)
							{
								t when timerafter(time + 100*MSEC_STD) :> time;
								ack = 1;
							}
							actual_position = get_position(c_position_ctrl) *pp_params.base.polarity;
							send_actual_position(actual_position, InOut);
						}
					}
					else if(op_mode == PV)
					{
						//printstr("PV ");
						if(ack == 1)
						{
							target_velocity = get_target_velocity(InOut);
							//printstr("tar vel ");printintln(target_velocity);
							actual_velocity = get_velocity(c_velocity_ctrl) *  pv_params.polarity;
							send_actual_velocity(actual_velocity, InOut);

							if(prev_velocity != target_velocity)
							{
								ack = 0;
								steps = init_velocity_profile(target_velocity, actual_velocity, \
										pv_params.profile_acceleration, pv_params.profile_deceleration,\
										pv_params.max_profile_velocity);

								//printstr("steps ");printintln(steps);
								i = 1;
								prev_velocity = target_velocity;
							}
						}
						else if(ack == 0)
						{
							if(i < steps)
							{
								velocity_ramp = velocity_profile_generate(i);
								//printintln(velocity_ramp);
								set_velocity( max_speed_limit(	(velocity_ramp) * pv_params.polarity,\
										pv_params.max_profile_velocity  ), c_velocity_ctrl );
								i++;
							}
							else if(i >= steps)
							{
								t when timerafter(time + 100*MSEC_STD) :> time;
								ack = 1;
							}
							actual_velocity = get_velocity(c_velocity_ctrl) *  pv_params.polarity;
							send_actual_velocity(actual_velocity, InOut);
						}
					}

#ifdef ENABLE_xscope_main
//					xscope_probe_data(0, actual_velocity);
//					xscope_probe_data(1, target_velocity);
#endif
					break;



				case 0x0006: //shutdown
					//deactivate
					if(op_mode == CSV || op_mode == PV)
					{
						shutdown_velocity_ctrl(c_velocity_ctrl);//p
						shutdown_ack = 1;
						op_set_flag = 0; init = 0;
						mode_selected = 0;  // to reenable the op selection and reset the controller
					}
					else if(op_mode == CSP || op_mode == PP)
					{
						shutdown_position_ctrl(c_position_ctrl);//p
						shutdown_ack = 1;
						op_set_flag = 0; init = 0;
						mode_selected = 0;  // to reenable the op selection and reset the controller
					}
					break;

			}
		}
//		printstr("mode ");printhexln(mode_selected);
//		printstr("mode q flag ");printhexln(mode_quick_flag);
//		printstr(" i ");printhexln(i);
//		printstr(" steps ");printhexln(steps);

		if(mode_selected == 3) // non interrupt
		{
			if(op_mode == CSV || op_mode == PV)
			{

				while(i < steps)
				{
					target_velocity = quick_stop_velocity_profile_generate(i);
					if(op_mode == CSV)
					{
						set_velocity( max_speed_limit(target_velocity, csv_params.max_motor_speed), c_velocity_ctrl );
						actual_velocity = get_velocity(c_velocity_ctrl);
						send_actual_velocity(actual_velocity * csv_params.polarity, InOut);
					}
					else if(op_mode == PV)
					{
						set_velocity( max_speed_limit(target_velocity, pv_params.max_profile_velocity), c_velocity_ctrl );
						actual_velocity = get_velocity(c_velocity_ctrl);
						send_actual_velocity(actual_velocity * pv_params.polarity, InOut);
					}
#ifdef ENABLE_xscope_main
//					xscope_probe_data(0, actual_velocity);
//					xscope_probe_data(1, target_velocity);
#endif

					t when timerafter(time + MSEC_STD) :> time;
					i++;
				}
				if(i == steps )
				{
					t when timerafter(time + 100*MSEC_STD) :> time;
				}
				if(i >= steps)
				{
					if(op_mode == CSV)
						send_actual_velocity(actual_velocity*csv_params.polarity, InOut);
					else if(op_mode == PV)
						send_actual_velocity(actual_velocity*pv_params.polarity, InOut);
					if(actual_velocity < 50 || actual_velocity > -50)
					{
						ctrlproto_protocol_handler_function(pdo_out, pdo_in, InOut);
						mode_selected = 100;
						op_set_flag = 0; init = 0;
					}
				}
				if(steps == 0)
				{
					mode_selected = 100;
					op_set_flag = 0; init = 0;

				}

			}
			else if(op_mode == CSP || op_mode == PP)
			{
				{actual_position, sense} = get_qei_position_count(c_qei_p4);
				while(i < steps)
				{
					target_position   =   quick_stop_position_profile_generate(i, sense);
					if(op_mode == CSP)
					{
						set_position( position_limit( target_position ,				\
								csp_params.max_position_limit * 10000  , 			\
								csp_params.min_position_limit * 10000) , c_position_ctrl);
						actual_position = get_position(c_position_ctrl);
						send_actual_position(actual_position * csp_params.base.polarity, InOut);
					}
					else if(op_mode == PP)
					{
						set_position( position_limit( target_position ,						\
								pp_params.software_position_limit_max * 10000  , 			\
								pp_params.software_position_limit_min * 10000) , c_position_ctrl);
						actual_position = get_position(c_position_ctrl);
						send_actual_position(actual_position * pp_params.base.polarity, InOut);
					}
//#ifdef ENABLE_xscope_main
				//	xscope_probe_data(0, actual_position);
				//	xscope_probe_data(1, target_position);
//#endif
					t when timerafter(time + MSEC_STD) :> time;
					i++;
				}
				if(i == steps )
				{
					t when timerafter(time + 100*MSEC_STD) :> time;
				}
				if(i >=steps )
				{
					actual_velocity = get_hall_speed(c_hall_p4, hall_params);
					actual_position = get_position(c_position_ctrl);
					if(op_mode == CSP)
						send_actual_position(actual_position * csp_params.base.polarity, InOut);
					else if(op_mode == PP)
						send_actual_position(actual_position*pp_params.base.polarity, InOut);
					if(actual_velocity < 50 || actual_velocity > -50)
					{
						mode_selected = 100;
						op_set_flag = 0; init = 0;
					}
				}
//#ifdef ENABLE_xscope_main
	//			xscope_probe_data(0, actual_position);
	//			xscope_probe_data(1, target_position);
//#endif
			}


		}
		if(mode_selected ==100)
		{
			if(mode_quick_flag == 0)
				quick_active = 1;

			if(op_mode == CSP)
			{
				actual_position = get_position(c_position_ctrl);
				send_actual_position(actual_position * csp_params.base.polarity, InOut);
			}
			else if(op_mode == PP)
			{
				actual_position = get_position(c_position_ctrl);
				send_actual_position(actual_position * pp_params.base.polarity, InOut);
			}
			else if(op_mode == CSV)
			{
				actual_velocity = get_velocity(c_velocity_ctrl);
				send_actual_velocity(actual_velocity*csv_params.polarity, InOut);
			}
			else if(op_mode == PV)
			{
				actual_velocity = get_velocity(c_velocity_ctrl);
				send_actual_velocity(actual_velocity*pv_params.polarity, InOut);
			}
			switch(InOut.operation_mode)
			{
				case 100:
					mode_selected = 0;
					quick_active = 0;
					mode_quick_flag = 1;
					InOut.operation_mode_display = 100;

					break;
			}
		//  xscope_probe_data(0, actual_position);
		//  xscope_probe_data(1, target_position);
		}
		t when timerafter(time + MSEC_STD) :> time;

	}
}
