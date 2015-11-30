/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IMF_BOARD_REQUIRED" WIT A APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_C22-rev-a.inc>
#include <IFM_DC100-rev-b.inc>

/**
 * @file test_qei.xc
 * @brief Test illustrates usage of qei sensor to get position and velocity information
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <print.h>
#include <refclk.h>
#include <xscope.h>

#include <qei_service.h>
#include <qei_config.h>

QEIPorts encoder_ports = ENCODER_PORTS;

/* Test QEI Sensor Client */
void qei_test(interface QEIInterface client i_qei)
{
	int position;
	int velocity;
	int direction;
	int core_id = 1;
	int count=0;
	timer t;

	while(1)
	{
		/* get position and velocity from QEI Sensor */
		{count, direction} = i_qei.get_qei_position_absolute();
		{position, direction} = i_qei.get_qei_position();

		velocity = i_qei.get_qei_velocity();

		xscope_int(COUNT, count);
		xscope_int(POSITION, position);
		xscope_int(VELOCITY, velocity);

		wait_ms(1, core_id, t);
	}
}

int main(void)
{
    interface QEIInterface i_qei[5];

	par
	{
		on tile[COM_TILE]:
		{
			/* Test QEI Sensor Client */
			qei_test(i_qei[0]);
		}

		/************************************************************
		 * IFM_TILE
		 ************************************************************/
		on tile[IFM_TILE]:
		{

			/* QEI Server Loop */
			{
			    QEIConfig qei_config;
			    init_qei_config(qei_config);

				qei_service(i_qei, encoder_ports, qei_config);  		// channel priority 1,2..6
			}
		}
	}

	return 0;
}
