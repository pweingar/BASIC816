;
STATUS_PORT 	        =	$AF1064
KBD_OUT_BUF 	        =	$AF1060
KBD_INPT_BUF	        = $AF1060
KBD_CMD_BUF		        = $AF1064
KBD_DATA_BUF	        = $AF1060
PORT_A			          =	$AF1060
PORT_B			          =	$AF1061

; Status
OUT_BUF_FULL  =	$01
INPT_BUF_FULL	=	$02
SYS_FLAG		  =	$04
CMD_DATA		  =	$08
KEYBD_INH     =	$10
TRANS_TMOUT	  =	$20
RCV_TMOUT		  =	$40
PARITY_EVEN		=	$80
INH_KEYBOARD	=	$10
KBD_ENA			  =	$AE
KBD_DIS			  =	$AD

; Keyboard Commands
KB_MENU			  =	$F1
KB_ENABLE		  =	$F4
KB_MAKEBREAK  =	$F7
KB_ECHO			  =	$FE
KB_RESET		  =	$FF
KB_LED_CMD		=	$ED

; Keyboard responses
KB_OK			    =	$AA
KB_ACK			  =	$FA
KB_OVERRUN		=	$FF
KB_RESEND		  =	$FE
KB_BREAK		  =	$F0
KB_FA			    =	$10
KB_FE			    =	$20
KB_PR_LED		  =	$40
