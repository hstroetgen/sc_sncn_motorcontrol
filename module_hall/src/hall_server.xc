/**
 * \file hall_server.xc
 *
 *	Hall Sensor Server
 *
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and Synapticon GmbH.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright 2013, Synapticon GmbH & XMOS Ltd. All rights reserved.
 * Authors: Martin Schwarz <mschwarz@synapticon.com>
 *
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code arse still covered by the
 * copyright notice above.
 *
 **/

#include "hall_server.h"
#include <stdlib.h>
#include <print.h>
#include <stdint.h>
#include "refclk.h"

void run_hall_new( chanend c_hall, chanend sensor_output, port in p_hall, hall_par &h_pole)
 {
  timer tx;
  unsigned ts;					// newest timestamp
  unsigned cmd;

  unsigned angle1;		        // newest angle (base angle on hall state transition)
  unsigned delta_angle;
  unsigned angle2;

  unsigned iCountMicroSeconds;
  int iHallActualSpeed=0;
  unsigned iPeriodMicroSeconds;
  unsigned iTimeCountOneTransition=0;
  unsigned iTimeSaveOneTransition=0;

  unsigned pin_state;			// newest hall state
  unsigned pin_state_last;
  unsigned new1,new2;
  unsigned uHallNext,uHallPrevious;
  int xreadings=0;
  int iPosAbsolut;

  int iHallError=0;
  int dir=0;


  unsigned uvalue, pos_cmd;
  signed spos, prev=0, count=0, co12=0,first=1,set=0;
  int hall_enc_count =  h_pole.pole_pairs * GEAR_RATIO * 4095;

  int pole_pairs = h_pole.pole_pairs;
  tx :> ts;  // first value

  while(1) {

	  switch(xreadings)
	  {
		  case 0: p_hall :> new1; new1 &= 0x07; xreadings++;
		  	  	  break;
		  case 1: p_hall :> new2; new2 &= 0x07;
				  if(new2 == new1) xreadings++;
				  else xreadings=0;
				  break;
		  case 2: p_hall :> new2; new2 &= 0x07;
				  if(new2 == new1) pin_state = new2;
				  else xreadings=0;
				  break;
	  }

	  iCountMicroSeconds++;   // period in �sec
	  iTimeCountOneTransition++;

      if(pin_state != pin_state_last)
      {
 	      if(pin_state == uHallNext)
 	      {
 	    	//  iPosAbsolut =  iPosAbsolut+60)%360;
 	    	  dir = 1;
 	      }
	      if(pin_state == uHallPrevious)
	      {
	    	 // iPosAbsolut = (iPosAbsolut-60)%360;
	    	  dir =-1;
	      }

	      //if(dir >= 0) // CW  3 2 6 4 5 1

	      switch(pin_state)
	  	  {
			  case 3: angle1 =     0;  uHallNext=2; uHallPrevious=1;  break;
			  case 2: angle1 =   682;  uHallNext=6; uHallPrevious=3;  break;   //  60
			  case 6: angle1 =  1365;  uHallNext=4; uHallPrevious=2;  break;
			  case 4: angle1 =  2048;  uHallNext=5; uHallPrevious=6;  break;   // 180
			  case 5: angle1 =  2730;  uHallNext=1; uHallPrevious=4;  break;
			  case 1: angle1 =  3413;  uHallNext=3; uHallPrevious=5;  break;   // 300 degree
			  default: iHallError++; break;
	  	  }


	    if(dir == 1)
	    	if(pin_state_last==1 && pin_state==3) // transition to NULL
	    	{
				 iPeriodMicroSeconds     = iCountMicroSeconds;
				 iCountMicroSeconds      = 0;
				 iHallActualSpeed        = 0;
	    		if(iPeriodMicroSeconds)
	    		{
	    			iHallActualSpeed = (60000000/iPeriodMicroSeconds)/POLE_PAIRS;    // period in �sec
					//iHallActualSpeed /= POLE_PAIRS; //Pole pairs
	    		}
	    	}

	    if(dir == -1)
	    	if(pin_state_last==3 && pin_state==1)
	    	{
				iPeriodMicroSeconds     = iCountMicroSeconds;
				iCountMicroSeconds      = 0;
				iHallActualSpeed        = 0;
	    		if(iPeriodMicroSeconds)
	    		{
	    			iHallActualSpeed = 0 - (60000000/iPeriodMicroSeconds)/POLE_PAIRS;
	    			//iHallActualSpeed = 60000000/iPeriodMicroSeconds;   	// transition 60 * 1000000 (sec multiplier) / time in Usec
					//iHallActualSpeed /= POLE_PAIRS;						// pole correction for speed
					//iHallActualSpeed = -iHallActualSpeed;
	    		}
	    	}

		   iTimeSaveOneTransition  = iTimeCountOneTransition;
		   iTimeCountOneTransition = 0;
		   delta_angle     = 0;
		   pin_state_last  = pin_state;

      }// end (pin_state != pin_state_last
     //===============================================================


	#define defPeriodMax 1000000  //1000msec
		if(iCountMicroSeconds > defPeriodMax)
			{
				iCountMicroSeconds = defPeriodMax;
				iHallActualSpeed=0;
			}


 		if(iTimeSaveOneTransition)
		delta_angle = (682 *iTimeCountOneTransition)/iTimeSaveOneTransition;
	  if(delta_angle >= 680) delta_angle = 680;

	  if(iTimeCountOneTransition > 50000) dir = 0;

	  angle2 = angle1;
      if(dir == 1)  angle2 += delta_angle;

      if(dir == -1) angle2 -= delta_angle;

      angle2 &= 0x0FFF;    // 4095

//	  tx :> ts;

      if(first == 1)
      {
		prev = angle2;
		first =0;  set = prev;
      }

	if( prev != angle2)
	{

		spos=angle2;
		if(spos-prev <= -1800){

				count = count + (4095 + spos-prev);
			   // c=c+1;
		          //forw
		}

		else if(spos-prev >= 1800){
					count = count + (-4095 + spos-prev);
			   // c=c-1;
		            // revr
		}

		else{

			count = count + spos-prev;
		}
		prev=angle2;

	}

	if(count>hall_enc_count || count< -hall_enc_count)
	{
		//printint( count);printstrln(" one");
		count=0;
	}


	#pragma ordered
 	    select {
			case c_hall :> cmd:
				  if  (cmd == 1) { c_hall <: angle2; }
			 else if  (cmd == 2) { c_hall <: iHallActualSpeed;  }
			 else if  (cmd == 3) { c_hall <: count;  }
			 else if  (cmd == 4) { c_hall <: iHallError;   }
			break;

			case sensor_output :> cmd:
				  if  (cmd == 1) { sensor_output <: angle2; }
			 else if  (cmd == 2) { sensor_output <: iHallActualSpeed;  }
			 else if  (cmd == 3) { sensor_output <: count;  }
			 else if  (cmd == 4) { sensor_output <: iHallError;   }
			break;
			default:
			  break;
 	    }// end of select
 	   tx when timerafter(ts + 250) :> ts;
  }// end while 1
}




