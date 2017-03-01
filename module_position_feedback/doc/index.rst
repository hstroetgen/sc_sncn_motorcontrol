.. _module_position_feedback:

========================
Position Feedback Module
========================

.. contents:: In this document
    :backlinks: none
    :depth: 3

This module provides a Service which starts one or two Position Sensor Services among BiSS, REM 16MT, REM 14, Hall and QEI. The service can also manage the GPIO ports.

The service takes as parameters:
 - ports for the different sensors
 - one config structure for each of the sensor services started (so 2 structures).
 - client interfaces to the shared memory for each of the sensor services (2).
 - server interfaces for the sensor services (2).

The service will initialize the ports and detect wrong configurations (for exemple starting two sensor services using the same ports). Then it will start one or two services. The second service is optional and will not be started if no config structure or server interface is provided it. The types of the sensor services started are set using the ``sensor_type`` parameter of the config structure.

The service provides an interface which can be used to get or set the configuration or the position data. This interface should only be used for configuration and debug purposes. For periodic data reading the shared memory should be used.

The shared memory is useful for other services to retrieve position and velocity data without blocking. There are 5 modes to configure which data is sent to the shared memory:
  - send nothing
  - send the electrical angle for commutation and the absolute position/velocity for motion control
  - send the electrical angle for commutation and the absolute position/velocity for secondary feedback (for display only)
  - send only the absolute position/velocity for motion control
  - send only the absolute position/velocity for secondary feedback (for display only)

The mode is set using the ``sensor_function`` parameter of the config structure.

It is possible to switch the sensor service type at runtime. You need fist to update the config structure to set the ``sensor_type`` that you want. Then you call the ``exit()`` interface which will restart the Position Feedback Service with the new sensor service.

This Service should always run over an **IFM Tile** so it can access the ports to
your SOMANET IFM device.


How to use
==========

.. important:: We assume that you are using :ref:`SOMANET Base <somanet_base>` and your app includes the required **board support** files for your SOMANET device.

.. seealso:: You might find useful the :ref:`Position feedback Demo <app_test_position_feedback>`, which illustrates the use of this module.

1. First, add all the :ref:`SOMANET Motor Control <somanet_motor_control>` modules to your app Makefile. The Position Feedback Service needs all the sensor modules it supports (BiSS, REM 16MT, REM 14, Hall and QEI).

    ::

        USED_MODULES = config_motor module_biss module_bldc_torque_control_lib module_board-support module_hall module_shared_memory module_misc module_position_feedback module_qei module_rem_14 module_rem_16mt module_serial_encoder module_spi_master

    .. note:: Not all modules will be required, but when using a library it is recommended to include always all the contained modules.
          This will help solving internal dependency issues.

2. Include the Position Feedback Service header **position_feedback_service.h** in your app.

3. Instantiate the ports needed for the sensors.

4. Inside your main function, instantiate the interfaces array for the Service-Clients communication.

5. At your IFM tile, instantiate the Service. For that, first you will have to fill up your Service configuration.

6. At whichever other core, now you can perform calls to the Position Feddback Service through the interfaces connected to it. Or if it is enabled you can read the position using the shared memory.

    .. code-block:: c

        #include <CORE_C22-rev-a.bsp>   //Board Support file for SOMANET Core C22 device
        #include <IFM_DC100-rev-b.bsp>  //Board Support file for SOMANET IFM DC100 device
                                        //(select your board support files according to your device)

        #include <position_feedback_service.h>
       
        QEIHallPort qei_hall_port_1 = SOMANET_IFM_HALL_PORTS;
        QEIHallPort qei_hall_port_2 = SOMANET_IFM_QEI_PORTS;
        HallEncSelectPort hall_enc_select_port = SOMANET_IFM_QEI_PORT_INPUT_MODE_SELECTION;
        SPIPorts spi_ports = SOMANET_IFM_SPI_PORTS;
        port ?gpio_port_0 = SOMANET_IFM_GPIO_D0;
        port ?gpio_port_1 = SOMANET_IFM_GPIO_D1;
        port ?gpio_port_2 = SOMANET_IFM_GPIO_D2;
        port ?gpio_port_3 = SOMANET_IFM_GPIO_D3;

        int main(void)
        {
            interface PositionFeedbackInterface i_position_feedback_1[3];
            interface PositionFeedbackInterface i_position_feedback_2[3];
            interface shared_memory_interface i_shared_memory[3];

            par
            {

                on tile[IFM_TILE]: par {
                    memory_manager(i_shared_memory, 3);

                    /* Position feedback service */
                    {
                        //set default parameters
                        PositionFeedbackConfig position_feedback_config;
                        position_feedback_config.polarity    = NORMAL_POLARITY;
                        position_feedback_config.pole_pairs  = POLE_PAIRS;
                        position_feedback_config.ifm_usec    = IFM_TILE_USEC;
                        position_feedback_config.max_ticks   = SENSOR_MAX_TICKS;
                        position_feedback_config.offset      = 0;

                        position_feedback_config.biss_config.multiturn_resolution = BISS_MULTITURN_RESOLUTION;
                        position_feedback_config.biss_config.filling_bits = BISS_FILLING_BITS;
                        position_feedback_config.biss_config.crc_poly = BISS_CRC_POLY;
                        position_feedback_config.biss_config.clock_frequency = BISS_CLOCK_FREQUENCY;
                        position_feedback_config.biss_config.timeout = BISS_TIMEOUT;
                        position_feedback_config.biss_config.busy = BISS_BUSY;
                        position_feedback_config.biss_config.clock_port_config = BISS_CLOCK_PORT;
                        position_feedback_config.biss_config.data_port_number = BISS_DATA_PORT_NUMBER;

                        position_feedback_config.rem_16mt_config.filter = REM_16MT_FILTER;

                        position_feedback_config.rem_14_config.hysteresis     = REM_14_SENSOR_HYSTERESIS ;
                        position_feedback_config.rem_14_config.noise_setting  = REM_14_SENSOR_NOISE;
                        position_feedback_config.rem_14_config.dyn_angle_comp = REM_14_SENSOR_DAE;
                        position_feedback_config.rem_14_config.abi_resolution = REM_14_SENSOR_ABI_RES;

                        position_feedback_config.qei_config.index_type  = QEI_SENSOR_INDEX_TYPE;
                        position_feedback_config.qei_config.signal_type = QEI_SENSOR_SIGNAL_TYPE;
                        position_feedback_config.qei_config.port_number = QEI_SENSOR_PORT_NUMBER;

                        position_feedback_config.hall_config.port_number = HALL_SENSOR_PORT_NUMBER;

                        position_feedback_config.gpio_config[0] = GPIO_INPUT_PULLDOWN;
                        position_feedback_config.gpio_config[1] = GPIO_OUTPUT;
                        position_feedback_config.gpio_config[2] = GPIO_OUTPUT;
                        position_feedback_config.gpio_config[3] = GPIO_OUTPUT;

                        PositionFeedbackConfig position_feedback_config_2;
                        position_feedback_config_2 = position_feedback_config;

                        //set sensor 1 parameters
                        position_feedback_config.sensor_type = HALL_SENSOR;
                        position_feedback_config.resolution  = HALL_SENSOR_RESOLUTION;
                        position_feedback_config.velocity_compute_period = HALL_SENSOR_VELOCITY_COMPUTE_PERIOD;
                        position_feedback_config.sensor_function = SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL;

                        //set sensor 1 parameters
                        position_feedback_config_2.sensor_type = BISS_SENSOR;
                        position_feedback_config_2.resolution  = BISS_SENSOR_RESOLUTION;
                        position_feedback_config.velocity_compute_period = BISS_SENSOR_VELOCITY_COMPUTE_PERIOD;
                        position_feedback_config_2.sensor_function = SENSOR_FUNCTION_FEEDBACK_ONLY;

                        position_feedback_service(qei_hall_port_1, qei_hall_port_2, hall_enc_select_port, spi_ports, gpio_port_0, gpio_port_1, gpio_port_2, gpio_port_3,
                                position_feedback_config, i_shared_memory[0], i_position_feedback,
                                position_feedback_config_2, null, i_position_feedback_2);
                    }
                }
            }

            return 0;
        }




API
===

Types
-----

.. doxygenenum:: GPIOType
.. doxygenenum:: SensorFunction
.. doxygenstruct:: GPIOConfig
.. doxygenstruct:: PositionFeedbackConfig

Service
--------

.. doxygenfunction:: position_feedback_service

Interface
---------

.. doxygeninterface:: PositionFeedbackInterface
