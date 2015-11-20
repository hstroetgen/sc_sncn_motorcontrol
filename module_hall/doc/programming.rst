.. _hall_programming_label:

Programming Guide
=================

Getting position and velocity information from your Hall sensor
---------------------------------------------------------------

Step 1: Include the required modules & headers
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Make sure you Makefile contains at least these module

::

    USED_MODULES = module_blocks module_hall module_motor module_motorcontrol_common module_board-support

Make sure you include these files in your main.xc file

::

    #include <xs1.h>
    #include <platform.h>
    #include <ioports.h>
    #include <hall_client.h>
    #include <hall_server.h>


Step 2: Define required channel
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
A channel is required to transport data from the hall_server task to your custom client's task

::

    int main(void)
    {
        chan c_hall
        ...
    }


Step 4: Run required tasks/servers: PWM, Commutation, Watchdog and Hall interface
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. important:: Please note that all these tasks must be executed on a tile with access to I/O of a Synapticon SOMANET IFM Drive DC board. 

::

    int main(void)
    {
    ...

        par
        {
        ...

            on tile[IFM_TILE]:
            {
                par
                {
                    /* Hall Server */
                    {
                        HallConfig hall_config;
                        run_hall(c_hall, NULL, NULL, NULL, NULL, NULL, p_ifm_hall, hall_config); // channel priority 1,2..6
                    }
                }
            }
            ...

        }

        return 0;
    }


Using hall_client to get velocity/position information
------------------------------------------------------
Getting velocity and position information from the hall server is easy:
::

    int main(void)
    {
    ...

        par
        {
            ...

            on tile[0]: // Can be any tile
            {
                /* Get position from Hall Sensor */
                {position, direction} = get_hall_position_absolute(c_hall);

                /* Get velocity from Hall Sensor */
                velocity = get_hall_velocity(c_hall);
            }
        }
        return 0;
    }
