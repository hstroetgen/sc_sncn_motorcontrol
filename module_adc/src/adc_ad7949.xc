/**
 * @file adc_server_ad7949.xc
 * @brief ADC Server
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <xs1.h>
#include <stdint.h>
#include <xclib.h>
#include <refclk.h>
#include <adc_ad7949.h>

/**
 * @brief Define bit masks to distinguish if a single bit is 0/1 in a 14 bit binary variable.
 */
#define BIT13 0x00002000
#define BIT12 0x00001000
#define BIT11 0x00000800
#define BIT10 0x00000400
#define BIT09 0x00000200
#define BIT08 0x00000100
#define BIT07 0x00000080
#define BIT06 0x00000040
#define BIT05 0x00000020
#define BIT04 0x00000010
#define BIT03 0x00000008
#define BIT02 0x00000004
#define BIT01 0x00000002
#define BIT0  0x00000001

/**
 * @brief Configure all ADC data ports
 *
 * @param clk                       XMOS internal clock
 * @param p_sclk_conv_mosib_mosia   32-bit buffered port to commiunicate with AD7949 through SPI
 * @param p_data_a                  32-bit buffered port to recieve the data from AD7949
 * @param p_data_b                  32-bit buffered port to recieve the data from AD7949
 *
 * @return void
 */
static void configure_adc_ports(
        clock clk,
        buffered out port:32 p_sclk_conv_mosib_mosia,
        in buffered port:32 p_data_a,
        in buffered port:32 p_data_b)
{
    /* SCLK period >= 22ns (45.45 MHz)
       clk needs to be configured twice as fast as the required SCLK frequency */
    configure_clock_rate_at_most(clk, 250, 7); // 83.3  --  < (2*45.45)

    /* when idle, keep clk and mosi low, conv high */
    configure_out_port(p_sclk_conv_mosib_mosia, clk, 0b0100);
    configure_in_port(p_data_a, clk);
    configure_in_port(p_data_b, clk);
    start_clock(clk);
}

/**
 * @brief Convert the output (serial) data of the adc in to unsigned value
 *
 * @param raw       Type unsigned value which is sent from AD7949 through SPI communication
 *
 * @return unsigned Converted Digital value of AD7949
 */
static inline unsigned convert(unsigned raw)
{
    unsigned int data;

    /* raw == 0b xxxx aabb ccdd eeff ...
       we read every data bit twice because of port clock setting */

    raw = bitrev(raw);
    data  = raw & 0x06000000;
    data >>= 2;
    data |= raw & 0x00600000;
    data >>= 2;
    data |= raw & 0x00060000;
    data >>= 2;
    data |= raw & 0x00006000;
    data >>= 2;
    data |= raw & 0x00000600;
    data >>= 2;
    data |= raw & 0x00000060;
    data >>= 2;
    data |= raw & 0x00000006;
    data >>= 1;
    return data;
}

/**
 * @brief Service to sample analogue inputs of ADC module
 *
 * @param iADC[2]               Interface to communicate with clients and send the measured values
 * @param adc_ports             Structure type to manage the AD7949 ADC chip.
 * @param current_sensor_config Structure type to calculate the proper sign (positive/negative) of sampled phase currents
 * @param i_watchdog            Interface to communicate with watchdog service
 * @param operational_mode      Reserved
 *
 * @return void
 */
void adc_ad7949(
        interface ADCInterface server iADC[2],
        AD7949Ports &adc_ports,
        CurrentSensorsConfig &current_sensor_config,
        interface WatchdogInterface client ?i_watchdog, int operational_mode)
{
    timer t;
    unsigned int time;

    /*
     * Configuration Register Description
     *
     * bit(s)   name    Description
     *
     *  13      CFG     Configuration udpate
     *  12      INCC    Input channel configuration
     *  11      INCC    Input channel configuration
     *  10      INCC    Input channel configuration
     *  09      INx     Input channel selection bit 2 0..7
     *  08      INx     Input channel selection bit 1
     *  07      INx     Input channel selection bit 0
     *  06      BW      Select bandwidth for low-pass filter
     *  05      REF     Reference/buffer selection
     *  04      REF     Reference/buffer selection
     *  03      REF     Reference/buffer selection
     *  02      SEQ     Channel sequencer. Allows for scanning channels in an IN0 to IN[7:0] fashion.
     *  01      SEQ     Channel sequencer
     *  00      RB      Read back the CFG register.
     *
     * Initialize the "Configuration Register":
     *
     * Overwrite configuration update | unipolar, referenced to GND | Motor current (ADC Channel IN0)| full Bandwidth | Internal reference, REF = 4,096V, temp enabled;
     * bit[13] = 1                      bits[12:10]: 111              bits[9:7] 000                    bit[6] 1         bits[5:3] 001
     *  Disable Sequencer | Do not read back contents of configuration
     *  bits[2:1] 00        bit[0] 1
     *
     */
    const unsigned int adc_config_mot=   0b11110001001001;
    unsigned int ad7949_config       =   0b11110001001001;

    unsigned int adc_data_a=0;
    unsigned int adc_data_b=0;

    unsigned int data_raw_a;
    unsigned int data_raw_b;

    int OUT_A[4], OUT_B[4];
    int j=0;

    const unsigned int channel_config[4] = {
            AD7949_CHANNEL_0,   // ADC Channel 2, unipolar, referenced to GND voltage and current
            AD7949_CHANNEL_2,   // ADC Channel 2, unipolar, referenced to GND voltage and current
            AD7949_CHANNEL_4,   // ADC Channel 4, unipolar, referenced to GND
            AD7949_CHANNEL_5};  // ADC Channel 5, unipolar, referenced to GND

    int i_calib_a = 10002, i_calib_b = 10002;

    int data_updated=0;

    int V_dc=0;
    int I_dc=0;

    int I_b=0;
    int I_c=0;

    int v_dc_max=100;
    int v_dc_min=0;
    int current_limit = 100;
    int fault_code=NO_FAULT;

    //proper task startup
    t :> time;
    t when timerafter (time + (3000*20*250)) :> void;

    configure_adc_ports(adc_ports.clk, adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b);

    while (1)
    {
#pragma ordered
        select
        {
        case iADC[int i].get_channel(unsigned short channel_in)-> {int output_a, int output_b}:
       // if (operational_mode==NORMAL_MODE)
       // {
       // adc_ports.p4_mux <: channel_in;
       // t :> time;
       // t when timerafter (time + 500) :> void;//5 us of wait
       //
       // clearbuf( adc_ports.p32_data[0] ); //Clear the buffers used by the input ports.
       // clearbuf( adc_ports.p32_data[1] );
       // adc_ports.p1_ready <: 1 @ time_stamp; // Switch ON input reads (and ADC conversion)
       // time_stamp += (ADC_TOTAL_BITS+2); // Allows sample-bits to be read on buffered input ports TODO: Check if +2 is cool enough and why
       // adc_ports.p1_ready @ time_stamp <: 0; // Switch OFF input reads, (and ADC conversion)
       //
       // sync( adc_ports.p1_ready ); // Wait until port has completed any pending outputs
       //
       // // Get data from port a
       // endin( adc_ports.p32_data[0] ); // End the previous input on this buffered port
       // adc_ports.p32_data[0] :> inp_val; // Get new input
       // tmp_val = bitrev( inp_val ); // Reverse bit order. WARNING. Machine dependent
       // tmp_val = tmp_val >> (SHIFTING_BITS+1);
       // tmp_val = (short)(tmp_val & ADC_MASK); // Mask out active bits and convert to signed word
       // output_a = (int)tmp_val;
       //
       // // Get data from port b
       // endin( adc_ports.p32_data[1] ); // End the previous input on this buffered port
       // adc_ports.p32_data[1] :> inp_val; // Get new input
       // tmp_val = bitrev( inp_val ); // Reverse bit order. WARNING. Machine dependent
       // tmp_val = tmp_val >> (SHIFTING_BITS+1);
       // tmp_val = (short)(tmp_val & ADC_MASK); // Mask out active bits and convert to signed word
       // output_b = (int)tmp_val;
       // }
       break;
        case iADC[int i].status() -> {int status}:
                status = ACTIVE;
                break;

        case iADC[int i].set_protection_limits_and_analogue_input_configs(
                int i_max_in, int i_ratio_in, int v_dc_max_in, int v_dc_min_in):
                v_dc_max=v_dc_max_in;
                v_dc_min=v_dc_min_in;
                current_limit = i_max_in * i_ratio_in;
                break;

        case iADC[int i].get_all_measurements() -> {
            int phaseB_out, int phaseC_out,
            int V_dc_out, int I_dc_out, int Temperature_out,
            int analogue_input_a_1, int analogue_input_a_2,
            int analogue_input_b_1, int analogue_input_b_2,
            int fault_code_out}:

            configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);

#pragma unsafe arrays
            int bits[4];

            bits[0]=0x80808000;
            if(adc_config_mot & BIT13)
                bits[0] |= 0x0000B300;
            if(adc_config_mot & BIT12)
                bits[0] |= 0x00B30000;
            if(adc_config_mot & BIT11)
                bits[0] |= 0xB3000000;

            bits[1]=0x80808080;
            if(adc_config_mot & BIT10)
                bits[1] |= 0x000000B3;
            if(adc_config_mot & BIT09)
                bits[1] |= 0x0000B300;
            if(adc_config_mot & BIT08)
                bits[1] |= 0x00B30000;
            if(adc_config_mot & BIT07)
                bits[1] |= 0xB3000000;

            bits[2]=0x80808080;
            if(adc_config_mot & BIT06)
                bits[2] |= 0x000000B3;
            if(adc_config_mot & BIT05)
                bits[2] |= 0x0000B300;
            if(adc_config_mot & BIT04)
                bits[2] |= 0x00B30000;
            if(adc_config_mot & BIT03)
                bits[2] |= 0xB3000000;

            bits[3]=0x00808080;
            if(adc_config_mot & BIT02)
                bits[3] |= 0x000000B3;
            if(adc_config_mot & BIT01)
                bits[3] |= 0x0000B300;
            if(adc_config_mot & BIT0)
                bits[3] |= 0x00B30000;

            stop_clock(adc_ports.clk);
            clearbuf(adc_ports.data_a);
            clearbuf(adc_ports.data_b);
            clearbuf(adc_ports.sclk_conv_mosib_mosia);
            adc_ports.sclk_conv_mosib_mosia <: bits[0];
            start_clock(adc_ports.clk);

            adc_ports.sclk_conv_mosib_mosia <: bits[1];
            adc_ports.sclk_conv_mosib_mosia <: bits[2];
            adc_ports.sclk_conv_mosib_mosia <: bits[3];

            sync(adc_ports.sclk_conv_mosib_mosia);
            stop_clock(adc_ports.clk);

            configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);

            adc_ports.data_a :> data_raw_a;
            adc_data_a = convert(data_raw_a);
            adc_ports.data_b :> data_raw_b;
            adc_data_b = convert(data_raw_b);

            configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);

            phaseB_out = (current_sensor_config.sign_phase_b * (((int) adc_data_a) - i_calib_a))/20;
            phaseC_out = (current_sensor_config.sign_phase_c * (((int) adc_data_b) - i_calib_b))/20;

            I_b = phaseB_out;
            I_c = phaseC_out;

            if( I_b<(-current_limit) || current_limit<I_b)
            {
                i_watchdog.protect(OVER_CURRENT_PHASE_B);
                if(fault_code==0) fault_code=OVER_CURRENT_PHASE_B;
            }

            if( I_c<(-current_limit) || current_limit<I_c)
            {
                i_watchdog.protect(OVER_CURRENT_PHASE_C);
                if(fault_code==0) fault_code=OVER_CURRENT_PHASE_C;
            }

            V_dc_out=OUT_A[AD_7949_VMOT_DIV_I_MOT];
            I_dc_out=OUT_B[AD_7949_VMOT_DIV_I_MOT];
            analogue_input_a_1 = OUT_A[AD_7949_EXT_A0_N_EXT_A1_N];
            analogue_input_b_1 = OUT_B[AD_7949_EXT_A0_N_EXT_A1_N];
            analogue_input_a_2 = OUT_A[AD_7949_EXT_A0_P_EXT_A1_P];
            analogue_input_b_2 = OUT_B[AD_7949_EXT_A0_P_EXT_A1_P];
            fault_code_out=fault_code;
            data_updated=1;
            break;

        case iADC[int i].reset_faults():
                I_b=0;
                I_c=0;
                fault_code=NO_FAULT;
                data_updated=0;
                i_watchdog.reset_faults();
                break;
        default:
            break;
        }

        if(data_updated==1)
        {
            for(j=AD_7949_EXT_A0_P_EXT_A1_P;AD_7949_IB_IC<=j;j--)
            {
                ad7949_config = channel_config[j];

                configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);

#pragma unsafe arrays
                int bits[4];

                bits[0]=0x80808000;
                if(ad7949_config & BIT13)
                    bits[0] |= 0x0000B300;
                if(ad7949_config & BIT12)
                    bits[0] |= 0x00B30000;
                if(ad7949_config & BIT11)
                    bits[0] |= 0xB3000000;

                bits[1]=0x80808080;
                if(ad7949_config & BIT10)
                    bits[1] |= 0x000000B3;
                if(ad7949_config & BIT09)
                    bits[1] |= 0x0000B300;
                if(ad7949_config & BIT08)
                    bits[1] |= 0x00B30000;
                if(ad7949_config & BIT07)
                    bits[1] |= 0xB3000000;

                bits[2]=0x80808080;
                if(ad7949_config & BIT06)
                    bits[2] |= 0x000000B3;
                if(ad7949_config & BIT05)
                    bits[2] |= 0x0000B300;
                if(ad7949_config & BIT04)
                    bits[2] |= 0x00B30000;
                if(ad7949_config & BIT03)
                    bits[2] |= 0xB3000000;

                bits[3]=0x00808080;
                if(ad7949_config & BIT02)
                    bits[3] |= 0x000000B3;
                if(ad7949_config & BIT01)
                    bits[3] |= 0x0000B300;
                if(ad7949_config & BIT0)
                    bits[3] |= 0x00B30000;

                for(int i=0;i<=3;i++)
                {
                    stop_clock(adc_ports.clk);
                    clearbuf(adc_ports.data_a);
                    clearbuf(adc_ports.data_b);
                    clearbuf(adc_ports.sclk_conv_mosib_mosia);
                    adc_ports.sclk_conv_mosib_mosia <: bits[0];
                    start_clock(adc_ports.clk);

                    adc_ports.sclk_conv_mosib_mosia <: bits[1];
                    adc_ports.sclk_conv_mosib_mosia <: bits[2];
                    adc_ports.sclk_conv_mosib_mosia <: bits[3];

                    sync(adc_ports.sclk_conv_mosib_mosia);
                    stop_clock(adc_ports.clk);

                    configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);

                    adc_ports.data_a :> data_raw_a;
                    adc_data_a = convert(data_raw_a);
                    adc_ports.data_b :> data_raw_b;
                    adc_data_b = convert(data_raw_b);

                    configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);
                }

                OUT_A[j] = ((int) adc_data_a);
                OUT_B[j] = ((int) adc_data_b);
            }
            data_updated=0;
        }
    }
}



