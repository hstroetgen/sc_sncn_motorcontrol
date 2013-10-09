/*
 * File:    qei_server.xc
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2013
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 */

#include "qei_server.h"

#include <xscope.h>

// Order is 00 -> 10 -> 11 -> 01
// Bit 3 = Index
static const unsigned char lookup[16][4] = {
		{ 5, 4, 6, 5 }, // 00 00
		{ 6, 5, 5, 4 }, // 00 01
		{ 4, 5, 5, 6 }, // 00 10
		{ 5, 6, 4, 5 }, // 00 11
		{ 0, 0, 0, 0 }, // 01 xx
		{ 0, 0, 0, 0 }, // 01 xx
		{ 0, 0, 0, 0 }, // 01 xx
		{ 0, 0, 0, 0 }, // 01 xx

		{ 5, 4, 6, 5 }, // 10 00
		{ 6, 5, 5, 4 }, // 10 01
		{ 4, 5, 5, 6 }, // 10 10
		{ 5, 6, 4, 5 }, // 10 11
		{ 0, 0, 0, 0 }, // 11 xx
		{ 0, 0, 0, 0 }, // 11 xx
		{ 0, 0, 0, 0 }, // 11 xx
		{ 0, 0, 0, 0 }  // 11 xx
};

void qei_client_hanlder(chanend c_qei, int command, int pos, int ok, int count, int direction, int velocity_raw, int velocity_raw1, int init_state, int neww)
{
	if(command == QEI_RAW_POS_REQ)
	{
		slave
		{
			c_qei <: pos;
			c_qei <: ok;
		}
	}
	else if(command == QEI_ABSOLUTE_POS_REQ)
	{
		slave
		{
			c_qei <: count;
			c_qei <: direction;
		}
	}
	else if(command == QEI_VELOCITY_REQ)
	{
		slave
		{
			c_qei <: velocity_raw;
		}
	}
	else if(command == QEI_VELOCITY_PWM_RES_REQ)
	{
		slave
		{
			c_qei <: velocity_raw1;
		}
	}
	else if(command == 5)
		slave

		{
			c_qei <: neww;
		}
	else if(command == CHECK_BUSY)
	{
		c_qei <: init_state;
	}
}
#pragma unsafe arrays
void run_qei ( port in p_qei, qei_par &qei_params, chanend c_qei_p1, chanend c_qei_p2, chanend c_qei_p3, chanend c_qei_p4)
{
	unsigned int pos = 0, v, ts1, ts2, ok=0, old_pins=0, new_pins;
	timer t;

	int command;
	int c_pos = 0, prev = 0, count = 0, first = 1;
	int max_count_actual = qei_params.gear_ratio * qei_params.real_counts;
	int difference = 0, direction = 0;
	int qei_max = qei_params.max_count;
	int qei_type = qei_params.index;
	int init_state = INIT;

	unsigned int time, time1;
	int s_previous_position1 = 0;
	int s_difference1 = 0;
	int old_difference1 = 0;
	int velocity_raw1 = 0;
	int filter_length1 = FILTER_LENGTH_QEI_PWM;
	int filter_buffer1[FILTER_LENGTH_QEI_PWM];
	int index1 = 0;

	int s_previous_position = 0;
	int s_difference = 0;
	int old_difference = 0;
	int velocity_raw = 0;
	int filter_length = FILTER_LENGTH_QEI;
	int filter_buffer[FILTER_LENGTH_QEI];						//default size used at compile time (cant be changed further)
	int index = 0;
	int flag = 0;
	int sync_position = 0;
	init_filter(filter_buffer, index, filter_length);
	init_filter(filter_buffer1, index1, filter_length1);
	p_qei :> new_pins;
	t :> ts1;
	t :> time1;
	t :> time;

	while (1) {
	#pragma ordered
		select {
			case p_qei when pinsneq(new_pins) :> new_pins :
				{
				  	  if ((new_pins & 0x3) != old_pins) {
				  		  ts2 = ts1;
				  		  t :> ts1;
				  	  }

				  	  if(qei_type == QEI_WITH_INDEX)
				  	  {
						  v = lookup[new_pins][old_pins];

						  if (!v) {
							  pos = 0;
							  ok = 1;
						  }
						  else
						  {
							  { v, pos } = lmul(1, pos, v, -5);
						  }
				  	  }
				  	  else if(qei_type == QEI_WITH_NO_INDEX)
				  	  {
				  		  v = lookup[new_pins][old_pins];
				  		  { v, pos } = lmul(1, pos, v, -5);
				  	  }

				  	  old_pins = new_pins & 0x3;

				  	if(first == 1)
					{
						prev = pos & (qei_max-1);
						first = 0;
					}
					c_pos =  pos & (qei_max-1);
					if(prev != c_pos )
					{
						difference = c_pos - prev;
						if( difference > 3000)
						{
							count = count + 1;
							direction = 1;

					//		 xscope_probe_data(3, ff);
						}
						else if(difference < -3000)
						{
							count = count - 1;

						//	xscope_probe_data(3, ff);
							direction = -1;
						}
						else if( difference < 10 && difference >0)
						{
							count = count - difference;
							direction = -1;

						}
						else if( difference < 0 && difference > -10)
						{

							count = count - difference;
							direction = 1;
						}
						prev = c_pos;
					}
					if(count >= max_count_actual || count <= -max_count_actual)
					{
						count=0;
					}
				}
				break;

			case c_qei_p1 :> command :
				qei_client_hanlder( c_qei_p1, command, pos, ok, count, direction, velocity_raw, velocity_raw1, init_state,sync_position);
				break;

			case c_qei_p2 :> command :
				qei_client_hanlder( c_qei_p2, command, pos, ok, count, direction, velocity_raw, velocity_raw1, init_state,sync_position);
				break;

			case c_qei_p3 :> command :
				qei_client_hanlder( c_qei_p3, command, pos, ok, count, direction, velocity_raw, velocity_raw1, init_state,sync_position);
				break;

			case c_qei_p4 :> command :
				qei_client_hanlder( c_qei_p4, command, pos, ok, count, direction, velocity_raw, velocity_raw1, init_state,sync_position);
				break;

//			case t when timerafter (time+MSEC_FAST):> time :
//				s_difference = count - s_previous_position;
//				if(s_difference > 3080)
//					s_difference = old_difference;
//				else if(s_difference < -3080)
//					s_difference = old_difference;
//				velocity_raw = _modified_internal_filter(filter_buffer, index, filter_length, s_difference);
//				s_previous_position = count;
//				old_difference = s_difference;
//				break;


		}

//		select
//		{
//			case t when timerafter (time1 + 13889):> time1 :
//				s_difference1 = count - s_previous_position1;
//				if(s_difference1 > 3080)
//					s_difference1 = old_difference1;
//				if(s_difference1 < -3080)
//					s_difference1 = old_difference1;
//				velocity_raw1 = _modified_internal_filter(filter_buffer1, index1, filter_length1, s_difference1);
//				s_previous_position1 = count;
//				old_difference1 = s_difference1;
//				break;
//			default:
//				break;
//		}
	}
}


