/**
 * @file adc_server_ad7949.xc
 * @brief ADC Server
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <xs1.h>
#include <stdint.h>
#include <xclib.h>
#include <refclk.h>
#include <print.h>
#include <adc_ad7949.h>
#include <xscope.h>


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

void output_adc_config_data(clock clk, in buffered port:32 p_data_a, in buffered port:32 p_data_b,
        buffered out port:32 p_adc, int adc_cfg_data)
{
#pragma unsafe arrays
    int bits[4];

    bits[0]=0x80808000;
    if(adc_cfg_data & BIT13)
        bits[0] |= 0x0000B300;
    if(adc_cfg_data & BIT12)
        bits[0] |= 0x00B30000;
    if(adc_cfg_data & BIT11)
        bits[0] |= 0xB3000000;

    bits[1]=0x80808080;
    if(adc_cfg_data & BIT10)
        bits[1] |= 0x000000B3;
    if(adc_cfg_data & BIT09)
        bits[1] |= 0x0000B300;
    if(adc_cfg_data & BIT08)
        bits[1] |= 0x00B30000;
    if(adc_cfg_data & BIT07)
        bits[1] |= 0xB3000000;

    bits[2]=0x80808080;
    if(adc_cfg_data & BIT06)
        bits[2] |= 0x000000B3;
    if(adc_cfg_data & BIT05)
        bits[2] |= 0x0000B300;
    if(adc_cfg_data & BIT04)
        bits[2] |= 0x00B30000;
    if(adc_cfg_data & BIT03)
        bits[2] |= 0xB3000000;

    bits[3]=0x00808080;
    if(adc_cfg_data & BIT02)
        bits[3] |= 0x000000B3;
    if(adc_cfg_data & BIT01)
        bits[3] |= 0x0000B300;
    if(adc_cfg_data & BIT0)
        bits[3] |= 0x00B30000;

    stop_clock(clk);
    clearbuf(p_data_a);
    clearbuf(p_data_b);
    clearbuf(p_adc);
    p_adc <: bits[0];
    start_clock(clk);

    p_adc <: bits[1];
    p_adc <: bits[2];
    p_adc <: bits[3];

    sync(p_adc);
    stop_clock(clk);
}

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


void adc_ad7949(
        interface ADCInterface server i_adc[2],
        AD7949Ports &adc_ports,
        CurrentSensorsConfig &current_sensor_config,
        interface WatchdogInterface client ?i_watchdog, int operational_mode)
{
    //    timer t;
    //    unsigned int time_end=0, time_start=0, period=0;
    //    unsigned int ad7949_config     =   0b11110001001001;   /* Motor current (ADC Channel 0), unipolar, referenced to GND */
    //
    //
    //    unsigned int adc_data_a[5];
    //    unsigned int adc_data_b[5];
    //    int i_calib_a = 0, i_calib_b = 0;
    //
    //    configure_adc_ports(adc_ports.clk, adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b);
    //
    //    i_calib_a = 10002;
    //    i_calib_b = 10002;
    //
    //    while (1)
    //    {
    //#pragma ordered
    //        select
    //        {
    //
    //        case i_adc[int i].status() -> {int status}:
    //                status = ACTIVE;
    //                break;
    //
    //        case i_adc[int i].set_protection_limits(int i_max_in, int i_ratio_in, int v_dc_max_in, int v_dc_min_in):
    //                break;
    //
    //        case i_adc[int i].set_channel(unsigned short channel_config):
    //                ad7949_config = channel_config;
    //                break;
    //
    //        case i_adc[int i].sample_and_send()-> {int out_a, int out_b}:
    //                t :> time_start;
    //
    //                unsigned int data_raw_a;
    //                unsigned int data_raw_b;
    //
    //
    //                /* Reading/Writing after conversion (RAC)
    //                                   Read previous conversion result
    //                                   Write CFG for next conversion */
    //
    //                // CONGIG__other_n1     CFG_Imotx_x1       |CONGIG__other_n2     CFG_Imotx_x2     |CONGIG__other_n3     CFG_Imotx_x3       |
    //                // CONVERT_null         CONVERT_other_n1   |CONVERT_Imot_x1      CONVERT_other_n2 |CONVERT_Imot_x2      CONVERT_other_n3   |
    //                // READOUT_null         READOUT_other_null |READOUT_other_n1     READOUT_Imot_x1  |READOUT_other_n2     READOUT_Imot_x2    |
    //                // -----------
    //                // iIndexADC        0           1                  2                  3
    //                // readout       extern     temperature     current-voltage         extern
    //
    //                configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);
    //
    //#pragma unsafe arrays
    //                int bits[4];
    //
    //                /*
    //                 * Configuration Register Description
    //                 *
    //                 * bit(s)   name    Description
    //                 *
    //                 *  13      CFG     Configuration udpate
    //                 *  12      INCC    Input channel configuration
    //                 *  11      INCC    Input channel configuration
    //                 *  10      INCC    Input channel configuration
    //                 *  09      INx     Input channel selection bit 2 0..7
    //                 *  08      INx     Input channel selection bit 1
    //                 *  07      INx     Input channel selection bit 0
    //                 *  06      BW      Select bandwidth for low-pass filter
    //                 *  05      REF     Reference/buffer selection
    //                 *  04      REF     Reference/buffer selection
    //                 *  03      REF     Reference/buffer selection
    //                 *  02      SEQ     Channel sequencer. Allows for scanning channels in an IN0 to IN[7:0] fashion.
    //                 *  01      SEQ     Channel sequencer
    //                 *  00      RB      Read back the CFG register.
    //                 */
    //
    //                bits[0]=0x80808000;
    //                if(ad7949_config & BIT13)
    //                    bits[0] |= 0x0000B300;
    //                if(ad7949_config & BIT12)
    //                    bits[0] |= 0x00B30000;
    //                if(ad7949_config & BIT11)
    //                    bits[0] |= 0xB3000000;
    //
    //                bits[1]=0x80808080;
    //                if(ad7949_config & BIT10)
    //                    bits[1] |= 0x000000B3;
    //                if(ad7949_config & BIT09)
    //                    bits[1] |= 0x0000B300;
    //                if(ad7949_config & BIT08)
    //                    bits[1] |= 0x00B30000;
    //                if(ad7949_config & BIT07)
    //                    bits[1] |= 0xB3000000;
    //
    //                bits[2]=0x80808080;
    //                if(ad7949_config & BIT06)
    //                    bits[2] |= 0x000000B3;
    //                if(ad7949_config & BIT05)
    //                    bits[2] |= 0x0000B300;
    //                if(ad7949_config & BIT04)
    //                    bits[2] |= 0x00B30000;
    //                if(ad7949_config & BIT03)
    //                    bits[2] |= 0xB3000000;
    //
    //                bits[3]=0x00808080;
    //                if(ad7949_config & BIT02)
    //                    bits[3] |= 0x000000B3;
    //                if(ad7949_config & BIT01)
    //                    bits[3] |= 0x0000B300;
    //                if(ad7949_config & BIT0)
    //                    bits[3] |= 0x00B30000;
    //
    //                for(int i=0;i<=3;i++)
    //                {
    //                    stop_clock(adc_ports.clk);
    //                    clearbuf(adc_ports.data_a);
    //                    clearbuf(adc_ports.data_b);
    //                    clearbuf(adc_ports.sclk_conv_mosib_mosia);
    //                    adc_ports.sclk_conv_mosib_mosia <: bits[0];
    //                    start_clock(adc_ports.clk);
    //
    //                    adc_ports.sclk_conv_mosib_mosia <: bits[1];
    //                    adc_ports.sclk_conv_mosib_mosia <: bits[2];
    //                    adc_ports.sclk_conv_mosib_mosia <: bits[3];
    //
    //                    sync(adc_ports.sclk_conv_mosib_mosia);
    //                    stop_clock(adc_ports.clk);
    //
    //                    configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);
    //
    //                    adc_ports.data_a :> data_raw_a;
    //                    adc_data_a[4] = convert(data_raw_a);
    //                    adc_ports.data_b :> data_raw_b;
    //                    adc_data_b[4] = convert(data_raw_b);
    //
    //                    configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);
    //                }
    //                out_a = ((int) adc_data_a[4]);
    //                out_b = ((int) adc_data_b[4]);
    //
    //                xscope_int (PERIOD, period);
    //
    //                t :> time_end;
    //                period = time_end-time_start;
    //
    //                break;
    //
    //        case i_adc[int i].get_all_measurements() -> {int phaseB_out, int phaseC_out, int V_dc_out, int torque_out, int fault_code_out}:
    //                break;
    //
    //        case i_adc[int i].reset_faults():
    //                break;
    //        }
    //    }
}


void adc_ad7949_fixed_channel(
        interface ADCInterface server i_adc[2],
        AD7949Ports &adc_ports,
        CurrentSensorsConfig &current_sensor_config,
        interface WatchdogInterface client ?i_watchdog, int operational_mode)
{
    timer t;
    unsigned int time, time_start=0, time_end=0, time_end_II=0, time_idle=0, period=0, period_II=0,
            time_end_mid=0, time_idle_mid=0;

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
     */

    /*
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

    unsigned int adc_data_a[5];
    unsigned int adc_data_b[5];

    unsigned int data_raw_a;
    unsigned int data_raw_b;

    int OUT_A[10], OUT_B[10];
    int j=0;
    int selected_channel=adc_config_mot;


    const unsigned int channel_config[4] = {
            AD7949_TEMPERATURE, // Temperature
            AD7949_CHANNEL_2,   // ADC Channel 2, unipolar, referenced to GND voltage and current
            AD7949_CHANNEL_4,   // ADC Channel 4, unipolar, referenced to GND
            AD7949_CHANNEL_5};  // ADC Channel 5, unipolar, referenced to GND

    int analogue_index_1=0, analogue_index_2=0;

    int i_calib_a = 0, i_calib_b = 0;

    int flag=0;

    int V_dc=0;
    int I_dc=0;

    int I_a=0;
    int I_b=0;
    int I_c=0;

    int i_max=100;
    int v_dc_max=100;
    int v_dc_min=0;
    int current_limit = i_max * 20;
    int fault_code=NO_FAULT;

    //proper task startup
    t :> time;
    t when timerafter (time + (3000*20*250)) :> void;

    configure_adc_ports(adc_ports.clk, adc_ports.sclk_conv_mosib_mosia, adc_ports.data_a, adc_ports.data_b);

    i_calib_a = 10002;
    i_calib_b = 10002;

    while (1)
    {
#pragma ordered
        select
        {
        case i_adc[int i].status() -> {int status}:
                status = ACTIVE;
                break;

//        case i_adc[int i].config_adc_inputs(unsigned int config_ai_1, unsigned int config_ai_2):
//                for(int i=0; i<=3; i++)
//                {
//                    if(config_ai_1 == channel_config[i])    analogue_index_1=i;
//                    if(config_ai_2 == channel_config[i])    analogue_index_2=i;
//                }
////                const unsigned int channel_config[4] = {
////                        AD7949_TEMPERATURE, // Temperature
////                        AD7949_CHANNEL_2, // ADC Channel 2, unipolar, referenced to GND voltage and current
////                        AD7949_CHANNEL_4, // ADC Channel 4, unipolar, referenced to GND
////                        AD7949_CHANNEL_5};  // ADC Channel 5, unipolar, referenced to GND
//                break;

        case i_adc[int i].set_protection_limits_and_analogue_input_configs(
                int i_max_in, int i_ratio_in, int v_dc_max_in, int v_dc_min_in,
                unsigned int config_ai_1, unsigned int config_ai_2):

                i_max=i_max_in;
                v_dc_max=v_dc_max_in;
                v_dc_min=v_dc_min_in;
                current_limit = i_max * i_ratio_in;

//                for(int i=0; i<=3; i++)
//                {
//                    if(config_ai_1 == channel_config[i])    analogue_index_1=i;
//                    if(config_ai_2 == channel_config[i])    analogue_index_2=i;
//                }
//                const unsigned int channel_config[4] = {
//                        AD7949_TEMPERATURE, // Temperature
//                        AD7949_CHANNEL_2, // ADC Channel 2, unipolar, referenced to GND voltage and current
//                        AD7949_CHANNEL_4, // ADC Channel 4, unipolar, referenced to GND
//                        AD7949_CHANNEL_5};  // ADC Channel 5, unipolar, referenced to GND
                break;

        case i_adc[int i].get_all_measurements() -> {
            int phaseB_out, int phaseC_out,
            int V_dc_out, int I_dc_out, int Temperature_out,
            int analogue_input_a_1, int analogue_input_a_2,
            int analogue_input_b_1, int analogue_input_b_2,
            int fault_code_out}:

                t:> time_start;
                time_idle = time_start-time_end_II;

                /* Reading/Writing after conversion (RAC)
                   Read previous conversion result
                   Write CFG for next conversion */

                // CONGIG__other_n1     CFG_Imotx_x1       |CONGIG__other_n2     CFG_Imotx_x2     |CONGIG__other_n3     CFG_Imotx_x3       |
                // CONVERT_null         CONVERT_other_n1   |CONVERT_Imot_x1      CONVERT_other_n2 |CONVERT_Imot_x2      CONVERT_other_n3   |
                // READOUT_null         READOUT_other_null |READOUT_other_n1     READOUT_Imot_x1  |READOUT_other_n2     READOUT_Imot_x2    |
                // -----------
                // iIndexADC        0           1                  2                  3
                // readout       extern     temperature     current-voltage         extern

                configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);

                fault_code_out = 0;

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
                adc_data_a[4] = convert(data_raw_a);
                adc_ports.data_b :> data_raw_b;
                adc_data_b[4] = convert(data_raw_b);

                configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);

                phaseB_out = (current_sensor_config.sign_phase_b * (((int) adc_data_a[4]) - i_calib_a))/20;
                phaseC_out = (current_sensor_config.sign_phase_c * (((int) adc_data_b[4]) - i_calib_b))/20;

                I_b = phaseB_out;
                I_c = phaseC_out;
                I_a = -I_b-I_c;

                if( I_a<(-current_limit) || current_limit<I_a)
                {
                    i_watchdog.protect(OVER_CURRENT_PHASE_A);
                    if(fault_code==0) fault_code=OVER_CURRENT_PHASE_A;
                }

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

                Temperature_out=0;

                analogue_input_a_1 = OUT_A[AD_7949_EXT_A0_N_EXT_A1_N];
                analogue_input_b_1 = OUT_B[AD_7949_EXT_A0_N_EXT_A1_N];

                analogue_input_a_2 = OUT_A[AD_7949_EXT_A0_P_EXT_A1_P];
                analogue_input_b_2 = OUT_B[AD_7949_EXT_A0_P_EXT_A1_P];

                fault_code_out=fault_code;

                flag=1;

                t :> time_end;
                period = time_end - time_start;

                break;

        case i_adc[int i].get_channel(unsigned short channel_config_in)-> {int out_a, int out_b}:

                if (operational_mode==NORMAL_MODE)
                {

                    ad7949_config = channel_config_in;

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
                        adc_data_a[4] = convert(data_raw_a);
                        adc_ports.data_b :> data_raw_b;
                        adc_data_b[4] = convert(data_raw_b);

                        configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);
                    }

                    out_a = ((int) adc_data_a[4]);
                    out_b = ((int) adc_data_b[4]);
                }

                break;

        case i_adc[int i].reset_faults():
                I_a=0;
                I_b=0;
                I_c=0;

                fault_code=NO_FAULT;
                flag=0;

                i_watchdog.reset_faults();
                break;
        default:
            break;
        }


        if(flag==1)
        {
            for(j=0;j<=3;j++)
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
                    adc_data_a[4] = convert(data_raw_a);
                    adc_ports.data_b :> data_raw_b;
                    adc_data_b[4] = convert(data_raw_b);

                    configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);
                }

                OUT_A[j] = ((int) adc_data_a[4]);
                OUT_B[j] = ((int) adc_data_b[4]);

                xscope_int(PERIOD, period);
                xscope_int(PERIOD_II, period_II);
                xscope_int(TIME_IDLE, time_idle);
                xscope_int(TIME_IDLE_MID, time_idle_mid);
            }
            t :> time_end_mid;
            time_idle_mid = time_start+7000 - time_end_mid;

            /*
             * the entire loop will be 83.3 us.
             * we need to start the sampling, 10 us before the adc is triggered.
             * so, it will be around 70 us after its previous triggered moment.
             * So, we wait until the moment t_start + 70us which is t_start+7000
             */
            t when timerafter (time_start + (7000)) :> void;

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
                adc_data_a[4] = convert(data_raw_a);
                adc_ports.data_b :> data_raw_b;
                adc_data_b[4] = convert(data_raw_b);

                configure_out_port(adc_ports.sclk_conv_mosib_mosia, adc_ports.clk, 0b0100);
            }

            flag=0;
            t :> time_end_II;
            period_II = time_end_II - time_start;

        }
    }
}



