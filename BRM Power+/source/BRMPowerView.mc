import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class BRMPowerView extends WatchUi.DataField {

    hidden var currentPower as Numeric;						// 현재 파워
    hidden var averagePower as Numeric;						// 평균 파워, NP 파워
    hidden var maxPower as Numeric;							// 최대 파워
	hidden var ssPower as Numeric;							// n초 평균파워
	hidden var lapPower as Numeric;
	hidden var npPower as Numeric;
	
	hidden var currentPowerZone as Numeric;					// 파원존
	hidden var PZ_decimal as Numeric;						// 파원존 소수
	hidden var pwrArray = [0.0,0.0,0.0,0.0,0.0,0.0,0.0];	// 파워존 카운트
	hidden var pwrNArray = [0.0,0.0,0.0,0.0,0.0,0.0,0.0];	// 파워존 퍼센트
	hidden var powerZoneThreshold = [110,150,180,210,240,300];
    
    hidden var arrPower as Array<Numeric> or Null;			// n초 계산용 파워 배열(30개) 정수로 저장해서 메모리 사용량 줄이기 
    hidden var count_n as Numeric;							// NP파워 카운터 : 평균계산
    hidden var lastNPower as Numeric;						// 이전 NP 파워 : 평균계산
	
	hidden var loc as Array<Numeric>;						// 위치변수
	hidden var fnt as Array<FontDefinition>;				// 폰트변수
	
	hidden var width as Numeric;							// 화면너비
	hidden var height as Numeric;							// 화면높이
	hidden var fontHeight as Numeric;						// 1040 판정용
	hidden var PZlocX = 0 as Numeric;						// 제목 위치 조정용
	hidden var normalizeOn = false as Boolean;				// 히스토그램 표시 grid 최대
	hidden var WOstate = 0 as Numeric;						// 훈련종류
	
	hidden var lapCount as Numeric;
	hidden var lastLapPower as Numeric;

	hidden var labelAvg;
	hidden var labelPersonal;
	hidden var metric;
	hidden var modePowerSS = new [4];
	hidden var modePowerAvg = new [7];
	hidden var WOlabel = new [13];

	hidden var smallFont as Boolean;
	hidden var POWERZONEBAR as Boolean;
	hidden var POWERZONEHISTORY as Boolean;
	hidden var nsec as Numeric;
	hidden var averageMode as Numeric;
//	hidden var showMaxPower as Boolean;
	hidden var theme as Numeric;
	hidden var fastColorValue as Numeric;
	hidden var slowColorValue as Numeric;
	hidden var pwrMode as Numeric;
	hidden var personalPower as Numeric;
	hidden var threshold as Numeric;
	hidden var manualPowerZone as Boolean;
	hidden var calcPowerZone as Boolean;
	hidden var FTP as Numeric;
	hidden var calcTypePZ as Numeric;
	hidden var setZoneColor as Boolean;
	
	hidden var elsdTime = 0 as Numeric;
	hidden var ShowTraining = false as Boolean;
	
	const RIGHT = Graphics.TEXT_JUSTIFY_RIGHT;
	const LEFT = Graphics.TEXT_JUSTIFY_LEFT;
	const RIGHTV = Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER;
	const LEFTV = Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER;
	
	//var test_v = 0;
	
    enum {
        THEME_NONE,
        THEME_RED,
        THEME_RED_INVERT,
        THEME_ZONES,
        INDICATE_HIGH,
        INDICATE_LOW,
        INDICATE_NORMAL
    }

    enum {
        MODE_AVERAGE,
        MODE_PERSONAL
    }

    function initialize() {
        DataField.initialize();
        
		currentPower = 0;
		averagePower = 0;
		maxPower = 0;
		ssPower = 0.0f;
		lapPower = 0.0f;
		npPower = 0.0f;
		currentPowerZone = 1;
		PZ_decimal = 0.0f;
		count_n = 0;
		lastNPower = 0.0f;
		loc = [140, 2, 100,38, 78,38, 136,25, 138,17, 104,56, 82,56, 6, 14]; 
		fnt = [Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_TINY];
		width = 140;
		height = 92;
		fontHeight = 47;
		arrPower = null;		
		pwrArray = [0.0,0.0,0.0,0.0,0.0,0.0,0.0];
		pwrNArray = [0.0,0.0,0.0,0.0,0.0,0.0,0.0];

		lapCount = 0;
		lastLapPower = 0.0f;

		labelAvg = loadResource(Rez.Strings.labelAvg);
		labelPersonal = loadResource(Rez.Strings.labelPersonal); 
		metric = loadResource(Rez.Strings.metric);
		
		smallFont = true;
		POWERZONEBAR = false;
		POWERZONEHISTORY = false;
		nsec = 3;
		averageMode = 2;
		theme = 1;
		fastColorValue = 3;
		slowColorValue = 8;
		pwrMode = 0;
		personalPower = 200;
		threshold = 5;
		manualPowerZone = false;
		calcPowerZone = true;
		FTP = 200;
		calcTypePZ = 0;
		setZoneColor = false;
		ShowTraining = false;
		
		initProperties();
		
		readModePower();
		readModeAverage();
		readWOlabel();
    }
    
    function initProperties() {
		if (Toybox.Application has :Properties) {
    		smallFont = Application.Properties.getValue("fontSize") == 0;
			POWERZONEBAR = Application.Properties.getValue("PowerZoneBar");
        	POWERZONEHISTORY = Application.Properties.getValue("PowerZoneHistory");
			nsec = Application.Properties.getValue("averageSec");
			averageMode = Application.Properties.getValue("averageMode");
//			showMaxPower = Application.Properties.getValue("showMaxPower");
        	theme = Application.Properties.getValue("theme");
	   		fastColorValue = Application.Properties.getValue("colorHigh");
	   		slowColorValue = Application.Properties.getValue("colorLow");
        	pwrMode = Application.Properties.getValue("powerMode");
			personalPower = 200;
        	threshold = Application.Properties.getValue("threshold");
			manualPowerZone = Application.Properties.getValue("manualPowerZone");
			calcPowerZone = Application.Properties.getValue("calcPowerZone");
			FTP = Application.Properties.getValue("FTP").toFloat();
			calcTypePZ = Application.Properties.getValue("calcTypePZ");
			setZoneColor = Application.Properties.getValue("theme") == 3;
			ShowTraining = Application.Properties.getValue("ShowTraining");

			// 파워
			// Zone 1 : 활성회복		 -	55%
			// Zone 2 : 지구력	 55% -	75%
			// Zone 3 : 템포 		 75% - 	90%
			// Zone 4 : 한계점 	 90% -	105%
			// Zone 5 : VO2Max	105% -	120%
			// Zone 6 : 무산소 	120% -	150%
			// Zone 7 : 신경근	150% -
	
			if (manualPowerZone) {
				if (Toybox.Application has :Properties) {
					powerZoneThreshold[0] = Application.Properties.getValue("Zone1maxValue");
					powerZoneThreshold[1] = Application.Properties.getValue("Zone2maxValue");
					powerZoneThreshold[2] = Application.Properties.getValue("Zone3maxValue");
					powerZoneThreshold[3] = Application.Properties.getValue("Zone4maxValue");
					powerZoneThreshold[4] = Application.Properties.getValue("Zone5maxValue");
					powerZoneThreshold[5] = Application.Properties.getValue("Zone6maxValue");
				} else {
					powerZoneThreshold[0] = 110;
					powerZoneThreshold[1] = 150;
					powerZoneThreshold[2] = 180;
					powerZoneThreshold[3] = 210;
					powerZoneThreshold[4] = 240;
					powerZoneThreshold[5] = 300;
				}
			} else if (calcPowerZone) {
				if (FTP == null || FTP == 0) { FTP=200; }
				switch(calcTypePZ) {
				case 1: 
					powerZoneThreshold[0] = Math.floor(FTP * 0.59);
					powerZoneThreshold[1] = Math.floor(FTP * 0.79);
					powerZoneThreshold[2] = Math.floor(FTP * 0.9);
					powerZoneThreshold[3] = Math.floor(FTP * 1.04);
					powerZoneThreshold[4] = Math.floor(FTP * 1.2);
					powerZoneThreshold[5] = Math.floor(FTP * 1.5);
					break;
				case 2:
					powerZoneThreshold[0] = Math.floor(FTP * 0.55);
					powerZoneThreshold[1] = Math.floor(FTP * 0.75);
					powerZoneThreshold[2] = Math.floor(FTP * 0.90);
					powerZoneThreshold[3] = Math.floor(FTP * 1.05);
					powerZoneThreshold[4] = Math.floor(FTP * 1.2);
					powerZoneThreshold[5] = Math.floor(FTP * 1.5);
					break;
				default:
					powerZoneThreshold[0] = Math.floor(FTP * 0.55);
					powerZoneThreshold[1] = Math.floor(FTP * 0.75);
					powerZoneThreshold[2] = Math.floor(FTP * 0.9);
					powerZoneThreshold[3] = Math.floor(FTP * 1.05);
					powerZoneThreshold[4] = Math.floor(FTP * 1.2);
					powerZoneThreshold[5] = Math.floor(FTP * 1.5);
				}
			} else {
				powerZoneThreshold = [110,150,180,210,240,300];
			}
			if (powerZoneThreshold[0] == null || powerZoneThreshold[0] == 0) {
				powerZoneThreshold = [110,150,180,210,240,300];
			}
		}
	}
    
    function onLayout(dc as Dc) as Void {
    	width = dc.getWidth();
    	fontHeight = dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM);
        //width = dc.getWidth();
        height = dc.getHeight();
		getLoc();
    	if (smallFont) {
			PZlocX = dc.getTextWidthInPixels("Z1", fnt[2]) * 0.5;
		} else {
			PZlocX = dc.getTextWidthInPixels("Z1", fnt[1]) * 0.5;
		}		
    }

	function getLoc() as Void {
		fnt = [Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_TINY];

        	// width(0), title(y1)
        	//          small      big        small      big        small             big
        	// half  pwr(x2,y3) pwr(x4,y5) avg(x6,y7) avg(x8,y9) metric(x10,y11) metric(x12,y13)
			// full  pwr(x2,y3)            avg(x6,y7)            metric(x10,y11) metric2(x12,y13)
			// label(x14,y15) arrow(x16,y17)
        switch (width) {
        	case 140: //Edge 1030, 1030 plus
        		if ( fontHeight != 48 ) {
	        		loc = [140, 2, 100,38, 78,38, 136,25, 138,17, 104,56, 82,56, 6, 14]; 
   	    		} else {//Edge 1040
	        		loc = [140, 2, 100,25, 82,37, 133,30, 135,20, 102,58, 86,58, 6, 14];
					fnt = [Graphics.FONT_NUMBER_HOT, Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL];
				}
        		break;
        	case 282: //Edge 1030, 1030 plus
        		if ( fontHeight != 48 ) {
					loc = [140, 2, 100,38, 240,38, 105,56, 240,68, 245,35, 141,48, 6, 14];
   	    		} else if (height > 100) {//Edge 1040
    	    		loc = [140, 2, 115,25, 245,25, 118,58, 242,58, 245,15, 141,45, 6, 14];
					fnt = [Graphics.FONT_NUMBER_HOT, Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL];
   	    		} else {//Edge 1040
    	    		loc = [140, 2, 115,25, 245,25, 118,58, 240,65, 245,33, 141,45, 6, 14];
					fnt = [Graphics.FONT_NUMBER_HOT, Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL];
				}
        		break;
        	case 119: //Edge 1000, Edge Explorer, Edge Explorer2
        		if ( fontHeight != 48 ) {
        			loc = [119, 2, 85,33, 68,33, 112,25, 115,18, 88,50, 72,50, 5, 12];
   	    		} else {
        			loc = [119, 2, 80,27, 72,27, 114,24, 118,18, 84,51, 74,51, 5, 12];
				}
        		break;
        	case 240: //Edge 1000, Edge Explorer, Edge Explorer2
        		if ( fontHeight != 48 ) {
        			loc = [119, 2, 85,32, 204,32, 89,49, 210,53, 215,28, 119,41, 5, 12];  
   	    		} else {
        			loc = [119, 2, 85,27, 205,27, 89,51, 210,55, 215,30, 118,43, 5, 12];
				}
        		break;
        	case 114: //Edge 130
        	case 115: //Edge 130 plus
        		loc = [115, 1, 65,23, 65,23, 110,24, 110,22, 67,45, 67,45, 4, 10];
				fnt = [Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_LARGE, Graphics.FONT_SMALL, Graphics.FONT_TINY];
        		break;
        	case 230: //Edge 130 plus
        		loc = [115, 1, 65,23, 180,23, 67,45, 182,45, 0,26, 114,42, 4, 10];
				fnt = [Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_LARGE, Graphics.FONT_SMALL, Graphics.FONT_TINY];
        		break;
        	case 99: //Edge 520, 520 plus
        		loc = [99, 0, 65,16, 65,16, 92,13, 92,13, 68,30, 68,30, 3, 8];
        		fnt = [Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_MEDIUM, Graphics.FONT_MEDIUM, Graphics.FONT_TINY];
        		break;
        	case 200: //Edge 520, 520 plus
        		loc = [99, 0, 67,16, 169,16, 70,30, 171,30, 3,14, 100,24, 3, 8];
        		fnt = [Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_MEDIUM, Graphics.FONT_MEDIUM, Graphics.FONT_TINY];
        		break;
        	case 122: //Edge 530, 830
        		loc = [122, 1, 87,21, 68,21, 119,17, 120,12, 91,40, 71,38, 4, 9];
        		if (fontHeight == 48) {
        			fnt = [Graphics.FONT_NUMBER_HOT, Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL];
        		}  
        		break;
        	case 246: //Edge 530, 830
        		loc = [122, 1, 84,21, 208,21, 88,38, 212,43, 215,18, 122,31, 4, 9];
        		break;
        	default:
        		loc = [140, 2, 100,38, 78,38, 136,25, 138,17, 104,56, 82,56, 5, 14]; 
        }
	}
	    
    function compute(info as Activity.Info) as Void {

		var elsd;
		if (info has :elapsedTime) {
			elsd = info.elapsedTime;
			if (elsd != null) {
				elsdTime = elsd / 1000;
			}
		}
		
		var crtPower;
		if (info has :currentPower ) {
			crtPower = info.currentPower;
			if (crtPower != null) {
				currentPower = crtPower;
			} else {
				currentPower = 0;
				return;
			}
		} else {
			currentPower = 0;
			return;
		}

		//currentPower = test_v * 11;
		//test_v++;

		if (currentPower != null && currentPower != 0) {
			computePowerZone(currentPower);
		} else {
			currentPowerZone = 1;
			PZ_decimal = 0.0f;
		}

        computePowers(info as Activity.Info, currentPower);		

        lapCount++;

		if (info.timerState == 0) { return; }
        if (POWERZONEHISTORY) {
			if (currentPowerZone >= 1 && currentPowerZone <= 7) {
        		if (currentPower > 0) {
        			var pwrCount = pwrArray[currentPowerZone-1];
        			pwrCount++; 
        			pwrArray[currentPowerZone-1] = pwrCount;
        		} else {
        			return; 
        		}
	    		if (!normalizeOn) {
        			if ( pwrArray[currentPowerZone-1] > loc[15] ) {
        				normalizeOn = true;
        			}
        		}
        	} else { return; }
        }
    }  

	function onTimerLap() {
		lapCount = 0;
		lastLapPower = 0.0f;
	}

	function computePowers(info as Activity.Info, crtPower as Numeric) as Void {

		// n초 평균파워 계산하기 PowerNs. 파워 30개 배열에서 n초만큼 추출=>sliceArr=>평균
		if ( info has :timerState && info.timerState == 0) { 
			arrPower = null;
			count_n = 0;
			lastNPower = 0.0f;			
			return; 
		}
		
		var sliceArr = null;
		var sizeArr = 0;
		var nPower = null;
		// 1초 파워 배열(30개)
		if (arrPower == null) {
			arrPower = [currentPower];
			sizeArr = 1;
			nPower = null;
		} else {
			sizeArr = arrPower.size();
			if(sizeArr < 30) {
				arrPower.add(currentPower);
				nPower = null;
			} else {
				arrPower = pushArray(arrPower, currentPower);
				nPower = meanArray(arrPower);
			}
		}
		
		switch(nsec) {
			case 1:
				ssPower = currentPower.toFloat();
				break;
			case 10:
				if (sizeArr <= 10) {
					ssPower = meanArray(arrPower);
				} else {
					sliceArr = arrPower.slice(-10,null);
					ssPower = meanArray(sliceArr);
				}
				break;
			case 30:
				if (nPower != null) {
					ssPower = nPower;
				} else {
					ssPower = meanArray(arrPower);
				}					
				break;
			default:
				if (sizeArr <= 3) {
					ssPower = meanArray(arrPower);
				} else {
					sliceArr = arrPower.slice(-3,null);
					ssPower = meanArray(sliceArr);
				}
		}
		sliceArr = null;

        var oldN = 0.0f;
	    var newN = 0.0f;
		switch(averageMode) {
		// Average
		case 0:
	        if (info has :averagePower && info.averagePower != null) {
    	    	averagePower = info.averagePower;
        	} else {
            	averagePower = 0;
        	}
        	break;
        // Max
		case 1:
	        if (info has :maxPower && info.maxPower != null) {
    	    	maxPower = info.maxPower;
        	} else {
            	maxPower = 0;
        	}
        	break;
        // Lap
        case 3:
        // Lap, NP
        case 6:
	        oldN = 0.0f;
    	    newN = 0.0f;
        	if (lapCount > 1) {
	        	oldN =  (lapCount - 1.0) / lapCount;
    	    	newN = 1.0 / lapCount;
        		lapPower = oldN * lastLapPower + newN * currentPower;
        		lastLapPower = lapPower.toNumber();
	        } else {
	        	lapPower = currentPower;
    	    	lastLapPower = currentPower;
        	}
        	break;
        // Average, Max
        case 4:
	        if (info has :averagePower && info.averagePower != null) {
    	    	averagePower = info.averagePower;
        	} else {
            	averagePower = 0;
        	}
	        if (info has :maxPower && info.maxPower != null) {
    	    	maxPower = info.maxPower;
        	} else {
            	maxPower = 0;
        	}
        	break;
        // Average, NP
        case 5:
	        if (info has :averagePower && info.averagePower != null) {
    	    	averagePower = info.averagePower;
        	} else {
            	averagePower = 0;
        	}
        	break;
        // Normal
		default:
        }
       	if (sizeArr<30) {
			npPower = 0;
		} else {
			npPower = meanNPArray(nPower).toNumber();
		}
        
	}

	function clearDC(dc as Dc) as Void {
		var backgroundColor = getBackgroundColor();
		var txtColor = backgroundColor == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        dc.setColor(txtColor, backgroundColor);
        dc.clear();
	}

    function onUpdate(dc as Dc) as Void {
		clearDC(dc);
		var bgColor = getBackgroundColor();
        var colors = {
        	:background => -1,
            :color => null,
            :pwr_color => null,
            :indication => INDICATE_NORMAL
        };
        var defaultColor, fastColor, slowColor;
        var backgroundColor = getBackgroundColor();
        var backgroundIsBlack = backgroundColor == Graphics.COLOR_BLACK;
        defaultColor = backgroundIsBlack ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        
        var LightFontColor = [
			Graphics.COLOR_RED,
			Graphics.COLOR_ORANGE,
			Graphics.COLOR_YELLOW,
			Graphics.COLOR_GREEN,
			Graphics.COLOR_BLUE,
			Graphics.COLOR_PURPLE,
			Graphics.COLOR_PINK,
			Graphics.COLOR_LT_GRAY,
			Graphics.COLOR_PINK
		];
		var DarkFontColor = [
			Graphics.COLOR_DK_RED,
			Graphics.COLOR_ORANGE,
			Graphics.COLOR_YELLOW,
			Graphics.COLOR_DK_GREEN,
			Graphics.COLOR_DK_BLUE,
			Graphics.COLOR_PURPLE,
			Graphics.COLOR_PINK,
			Graphics.COLOR_DK_GRAY,
			Graphics.COLOR_DK_RED
		];

		if (backgroundIsBlack) {
			fastColor = LightFontColor[fastColorValue];
			slowColor = LightFontColor[slowColorValue];
		} else {
			fastColor = DarkFontColor[fastColorValue];
			slowColor = DarkFontColor[slowColorValue];
		}
		LightFontColor = null;
		DarkFontColor = null;
        
        if (ssPower != null) {
			var variations = getVariations();
			switch(theme) {
			case THEME_RED:
	   		    if (ssPower > variations[:max]) {
					colors[:pwr_color] = fastColor;
					colors[:color] = defaultColor;
					colors[:indication] = INDICATE_HIGH;
        	   	} else if (ssPower < variations[:min]) {
					colors[:pwr_color] = slowColor;
					colors[:color] = defaultColor;
					colors[:indication] = INDICATE_LOW;
    	    	} else {
					colors[:pwr_color] = defaultColor;
					colors[:color] = defaultColor;
	       	    }
       	    	break;
			case THEME_RED_INVERT:
	   		    if (ssPower > variations[:max]) {
					colors[:background] = Graphics.COLOR_DK_RED;
					colors[:pwr_color] = Graphics.COLOR_WHITE;
					colors[:color] = Graphics.COLOR_WHITE;
					colors[:indication] = INDICATE_HIGH;
        	   	} else if (ssPower < variations[:min]) {
					colors[:background] = Graphics.COLOR_DK_GREEN;
					colors[:pwr_color] = Graphics.COLOR_WHITE;
					colors[:color] = Graphics.COLOR_WHITE;
					colors[:indication] = INDICATE_LOW;
    	    	} else {
					colors[:pwr_color] = defaultColor;
					colors[:color] = defaultColor;
	       	    }
       	    	break;
       	    case THEME_ZONES:
		    	var powerZoneColor = [
					Graphics.COLOR_LT_GRAY,
	    		    Graphics.COLOR_BLUE,
    	    		Graphics.COLOR_GREEN,
		        	Graphics.COLOR_YELLOW,
    		    	Graphics.COLOR_PINK,
    			    Graphics.COLOR_RED,
    			    Graphics.COLOR_RED
				];
				if (bgColor != Graphics.COLOR_BLACK) {
					powerZoneColor = [
						Graphics.COLOR_DK_GRAY,
		    	    	Graphics.COLOR_DK_BLUE,
    		    		Graphics.COLOR_DK_GREEN,
        				Graphics.COLOR_ORANGE,
        				Graphics.COLOR_PURPLE,
    			    	Graphics.COLOR_DK_RED,
    			    	Graphics.COLOR_DK_RED
					];
				}
				var pzColor = powerZoneColor[currentPowerZone-1];
				powerZoneColor = null;
				colors[:pwr_color] = pzColor;
				colors[:color] = defaultColor;
				colors[:indication] = defaultColor;
       	    	break;
       	    default:
				colors[:pwr_color] = defaultColor;
				colors[:color] = defaultColor;
			}       	    
       	} else {
				colors[:pwr_color] = defaultColor;
				colors[:color] = defaultColor;
       	}

        dc.setColor(colors[:color], colors[:background]);
        dc.clear();
       	
		drawPowerZones(dc, colors);
		
		drawPowerData(dc,colors);

    	width = dc.getWidth();
        var fullWidth = width > loc[0];
		// Full 화면모드에서 화살포 그리기
        if (!fullWidth) {	return;	}
        drawArrows(dc, colors);
    }

    function getComparablePower() as Number {
        if (pwrMode == MODE_PERSONAL) {
            	return personalPower;
		} 
		
		switch (averageMode) {
			case 0 :
				return averagePower;
			case 1 :
				return maxPower;
			case 2 :
				return npPower;
			case 3 :
				return lapPower;
			default :
				return 0;
		}
    }

    function getVariations() as Dictionary {
        var compareable = getComparablePower();				// Number
        var control = compareable * (threshold/100.0);		// Number
        return {
            :min => compareable - control,					// Number
            :max => compareable + control					// Number
        };
    }

	// Full 화면 모드에서 화살표 그리기 함수
    function drawArrows(dc as Dc, colors as Dictionary) as Void {
        var center = loc[12];
        var vcenter = loc[13];
        if (height > 100) {
        	vcenter = vcenter + height * 0.1;
        }

        // up arrow, 13x7
        dc.setColor(colors[:indication] == INDICATE_HIGH ? colors[:pwr_color] : Graphics.COLOR_LT_GRAY, colors[:background]);
        if (loc[0]==115) {
        	if (colors[:indication] == INDICATE_HIGH) {
	        	dc.setColor(Graphics.COLOR_BLACK, colors[:background]);
    	    	dc.fillPolygon([[center - 6, vcenter + 6], [center, vcenter], [center + 6, vcenter + 6]]);
        	} else {
	        	dc.setColor(Graphics.COLOR_BLACK, colors[:background]);
    	    	dc.drawLine(center - 6, vcenter + 6, center, vcenter);
        		dc.drawLine(center - 6, vcenter + 6, center + 6, vcenter + 6);
        		dc.drawLine(center, vcenter, center + 6, vcenter + 6);
        	}
		} else {        	
			dc.fillPolygon([[center - 6, vcenter + 6], [center, vcenter], [center + 6, vcenter + 6]]);
		}

        // down arrow, 13x7
        dc.setColor(colors[:indication] == INDICATE_LOW ? colors[:pwr_color] : Graphics.COLOR_LT_GRAY, colors[:background]);
        if (loc[0]==115) {
        	if ( colors[:indication] == INDICATE_LOW) {
	        	dc.setColor(Graphics.COLOR_BLACK, colors[:background]);
		        dc.fillPolygon([[center - 6, vcenter + 10], [center, vcenter + 16], [center + 6, vcenter + 10]]);
	    	} else if (loc[0] == 115) {
        		dc.setColor(Graphics.COLOR_BLACK, colors[:background]);
	        	dc.drawLine(center - 6, vcenter + 10, center, vcenter + 16);
    	    	dc.drawLine(center - 6, vcenter + 10, center + 6, vcenter + 10);
        		dc.drawLine(center, vcenter + 16, center + 6, vcenter + 10);
        	}
		} else {
	        dc.fillPolygon([[center - 6, vcenter + 10], [center, vcenter + 16], [center + 6, vcenter + 10]]);
		}	    
    }

    function computePowerZone(pwr as Number) {
		
		if (currentPower !=null) {
			if (pwr <= powerZoneThreshold[0]) {
				currentPowerZone = 1;
				PZ_decimal = pwr / powerZoneThreshold[0];
				return;
			} else if (pwr > powerZoneThreshold[5]) {
				currentPowerZone = 7; 
				PZ_decimal = (pwr - powerZoneThreshold[5]) / (powerZoneThreshold[5] * 2.0);
				if (PZ_decimal > 1) { PZ_decimal = 1.0; }
				return; 
			}
			
			for (var pwr_i=1;pwr_i<6;pwr_i++) {
				if (pwr > powerZoneThreshold[pwr_i-1] && pwr <= powerZoneThreshold[pwr_i]) {
					currentPowerZone = pwr_i + 1;
					var minZone = powerZoneThreshold[pwr_i-1].toFloat();
					var maxZone = powerZoneThreshold[pwr_i].toFloat();
					PZ_decimal = (pwr.toFloat() - minZone) / (maxZone - minZone);
					return;
				} 
			}
		}
	}

	function drawPowerZones(dc as Dc, colors as Dictionary) {
		width = dc.getWidth();
	    var fullWidth = width > loc[0];
	    var bgColor = getBackgroundColor();
	    var defaultColor = (bgColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

		var zone_w = (width - loc[14] * 2.0 ) / 7.0;
		var y_bottom = dc.getHeight();

		var setZoneColor = false;

    	var powerZoneColor = [
			Graphics.COLOR_LT_GRAY,
	        Graphics.COLOR_BLUE,
    	    Graphics.COLOR_GREEN,
        	Graphics.COLOR_YELLOW,
        	Graphics.COLOR_PINK,
    	    Graphics.COLOR_RED,
    	    Graphics.COLOR_RED
		];
		if (bgColor == Graphics.COLOR_BLACK || height > 100) {
			powerZoneColor = [
				Graphics.COLOR_DK_GRAY,
		        Graphics.COLOR_DK_BLUE,
    		    Graphics.COLOR_DK_GREEN,
        		Graphics.COLOR_ORANGE,
        		Graphics.COLOR_PURPLE,
    	    	Graphics.COLOR_DK_RED,
    	    	Graphics.COLOR_DK_RED
			];
		}
		if (loc[0]==115) {
			powerZoneColor = [
				Graphics.COLOR_DK_GRAY,
		        Graphics.COLOR_DK_BLUE,
		   	    Graphics.COLOR_DK_GREEN,
		       	Graphics.COLOR_ORANGE,
		       	Graphics.COLOR_ORANGE,
		   	    Graphics.COLOR_DK_RED,
		   	    Graphics.COLOR_DK_RED
			];
		}

		if (POWERZONEBAR) {
			dc.setColor(powerZoneColor[0], -1);
			dc.fillRectangle(loc[14], y_bottom - loc[14], zone_w - 1, loc[14]);
			//dc.drawText(width / 7 * 0.5 , y_bottom - 30, Graphics.FONT_TINY, pwrArray[0].format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER);

			dc.setColor(powerZoneColor[1], -1);
			dc.fillRectangle(loc[14] + zone_w, y_bottom - loc[14], zone_w - 1, loc[14]);
			//dc.drawText(width / 7 * 1.5 , y_bottom - 30, Graphics.FONT_TINY, pwrArray[1].format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER);

			dc.setColor(powerZoneColor[2], -1);
			dc.fillRectangle(loc[14] + zone_w * 2.0, y_bottom - loc[14], zone_w - 1, loc[14]);
			//dc.drawText(width / 7 * 2.5 , y_bottom - 30, Graphics.FONT_TINY, pwrArray[2].format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER);

			dc.setColor(powerZoneColor[3], -1);
			dc.fillRectangle(loc[14] + zone_w * 3.0, y_bottom - loc[14], zone_w - 1, loc[14]);
			//dc.drawText(width / 7 * 3.5 , y_bottom - 30, Graphics.FONT_TINY, pwrArray[3].format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER);

			dc.setColor(powerZoneColor[4], -1);
			dc.fillRectangle(loc[14] + zone_w * 4.0, y_bottom - loc[14], zone_w - 1, loc[14]);
			//dc.drawText(width / 7 * 4.5 , y_bottom - 30, Graphics.FONT_TINY, pwrArray[4].format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER);

			dc.setColor(powerZoneColor[5], -1);
			dc.fillRectangle(loc[14] + zone_w * 5.0, y_bottom - loc[14], zone_w - 1, loc[14]);
			//dc.drawText(width / 7 * 5.5 , y_bottom - 30, Graphics.FONT_TINY, pwrArray[5].format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER);

			dc.setColor(powerZoneColor[6], -1);
			dc.fillRectangle(loc[14] + zone_w * 6.0, y_bottom - loc[14], zone_w - 1, loc[14]);
			//dc.drawText(width / 7 * 6.5 , y_bottom - 30, Graphics.FONT_TINY, pwrArray[6].format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER);
		}

        var vcenter = y_bottom - loc[14];
		if (POWERZONEHISTORY) {
		    var gridArray = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
			gridArray = normalizeArray();
			for (var inc_j=0; inc_j<7; inc_j++) {
       	 		dc.setColor(powerZoneColor[inc_j], -1);
				var x = loc[14] + zone_w * inc_j;
				var y; 
	        	for (var inc_k=0; inc_k < gridArray[inc_j]; inc_k++) {
        		 	y = vcenter - (inc_k + 1) * 4;
        			dc.drawLine (x, y, x + zone_w - 1, y);  
    	    	}
	        } 
		}
		powerZoneColor = null;

		var center = 140;
		if (POWERZONEBAR) {
	        var arrColor = bgColor == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
    	    var arrSize = loc[14];
			if (currentPowerZone == 7 && PZ_decimal == 1) {
        		center = loc[14] + zone_w * 7;
	        } else {
    	    	center = loc[14] + zone_w * (currentPowerZone-1) + zone_w * PZ_decimal;
        	}
	       if (loc[0] == 115) { 
    	    	arrColor = Graphics.COLOR_WHITE; 
        		dc.setColor(arrColor, -1);
         		dc.fillPolygon([[center - arrSize, vcenter + arrSize], [center, vcenter], [center + arrSize, vcenter + arrSize]]);
	        } else if (loc[0] == 99 || loc[0] == 122) { 
    	    	dc.setColor(arrColor, -1);
        		dc.fillPolygon([[center - arrSize, vcenter + arrSize], [center, vcenter], [center + arrSize, vcenter + arrSize]]);
	        } else {
    	    	dc.setColor(arrColor, -1);
        		dc.fillPolygon([[center - arrSize, vcenter - arrSize], [center, vcenter], [center + arrSize, vcenter - arrSize]]);
        	}
        }
	}
	
	function drawPowerData(dc as Dc, colors as Dictionary) {
		width = dc.getWidth();
		var h_val = height * 0.1;
	    var bgColor = getBackgroundColor();

		var powerZoneColor;
		if (bgColor == Graphics.COLOR_BLACK) {
			powerZoneColor = [
				Graphics.COLOR_LT_GRAY,
		        Graphics.COLOR_BLUE,
    		    Graphics.COLOR_GREEN,
        		Graphics.COLOR_YELLOW,
        		Graphics.COLOR_PINK,
    		    Graphics.COLOR_RED,
    		    Graphics.COLOR_RED
			];
		} else {
			powerZoneColor = [
				Graphics.COLOR_DK_GRAY,
		        Graphics.COLOR_DK_BLUE,
		   	    Graphics.COLOR_DK_GREEN,
		       	Graphics.COLOR_ORANGE,
		       	Graphics.COLOR_PURPLE,
		   	    Graphics.COLOR_DK_RED,
		   	    Graphics.COLOR_DK_RED
			];
		}
		var pzColor = powerZoneColor[currentPowerZone-1];
		powerZoneColor = null;

		var field = 0;
		if (width > loc[0]) {
			// Full Field
			field = 0;
			if (averageMode > 3) { field = 1; }
		} else if (!smallFont) {
			// Half 큰글씨
			field = 2;
			if (averageMode > 3) { field = 3; }
		} else {
			// Half 작은글씨
			field = 4;
			if (averageMode > 3) { field = 5; }
		} 

		var pwrv;
		var pzv;
		switch (field) {
			// Full
			case 0:
				if (loc[0]==122) { 
					pwrv = [loc[2], loc[3], fnt[0]];
					pzv = [loc[14], loc[1], fnt[2], LEFT];
				} else if (height > 100) {
					pwrv = [loc[2], loc[3] + h_val, fnt[0]];
					pzv = [loc[14], loc[1], fnt[1], LEFT];
				} else {
					pwrv = [loc[2], loc[3], fnt[0]];
					pzv = [loc[14], loc[1], smallFont ? fnt[2] : fnt[1], LEFT];
				}
				break;
			// Full x 2
			case 1: 
				
				if (loc[0]==122) {
					pwrv = [loc[2], loc[3], fnt[0]]; 
					pzv = [loc[14], loc[1], fnt[2], LEFT];
				} else if (height > 100) {
					pwrv = [loc[2], loc[3] + h_val, fnt[0]];
					pzv = [loc[14], loc[1], fnt[1], LEFT];
				} else {
					pwrv = [loc[2], loc[3], fnt[0]];
					pzv = [loc[14], loc[1], smallFont ? fnt[2] : fnt[1], LEFT];
				}
				break;
			// Half Big
			case 2:
				pwrv = [loc[4], loc[5], fnt[0]];
				if (width==140&&fontHeight==48) {
					pwrv[2] = Graphics.FONT_NUMBER_MEDIUM;
				}
				pzv = [loc[14], loc[9], fnt[1], LEFTV];
				break;
			// Half Big x 2
			case 3:
				pwrv = [loc[4], loc[5], fnt[0]];
				if (width==140&&fontHeight==48) {
					pwrv[2] = Graphics.FONT_NUMBER_MEDIUM;
				}
				pzv = [loc[14], loc[9], fnt[1], LEFTV];
				break;
			// Half Small
			case 4:
				pwrv = [loc[2]*0.95, loc[3], fnt[0]];
				pzv = [loc[14], loc[1], fnt[2], LEFT];
				break;
			// Half Small x 2
			case 5:					
				pwrv = [loc[2]*0.95, loc[3], fnt[0]];
				pzv = [loc[14], loc[1], fnt[2], LEFT];
				break;
			default:
				pwrv = [loc[2], loc[3], fnt[0]];
				pzv = [loc[14], loc[1], fnt[2], LEFT];
		}

		// 파워 글자 색상 지정
		if (ssPower !=null && ssPower >=0) {
			dc.setColor(colors[:pwr_color], -1);
			if (setZoneColor) {
				dc.setColor(pzColor, -1);
			}
    	   	dc.drawText(pwrv[0], pwrv[1], pwrv[2], ssPower.format("%d"), Graphics.TEXT_JUSTIFY_RIGHT);
		}
		pwrv = null;
		dc.setColor(pzColor, colors[:background]);
       	dc.drawText(pzv[0], pzv[1], pzv[2], "Z" + currentPowerZone.format("%d"), pzv[3]);
		pzv = null;

		// 평균파워 표시
		var avgPWR = "";
		var avgPWR2 = "";
		var met1 = "";
		var met2 = "";
		switch(averageMode) {
			case 0:  // 평균파워
				avgPWR = averagePower.format("%d");
				break;
			case 1:  // 최대파워
				avgPWR = maxPower.format("%d");
				break;
			case 2:  // 노말파워
				avgPWR = npPower.format("%d");
				break;
			case 3:  // 랩 파워
				avgPWR = lapPower.format("%d");
				break;
			case 4:  // 평균 / 최대파워
				avgPWR = averagePower.format("%d");
				avgPWR2 = maxPower.format("%d");
				met1 = modePowerAvg[0];
				met2 = modePowerAvg[1];
				break;
			case 5:  // 평균 / 노말파워
				avgPWR = averagePower.format("%d");
				avgPWR2 = npPower.format("%d");
				met1 = modePowerAvg[0];
				met2 = modePowerAvg[2];
				break;
			case 6:  // 램 / 노말파워
				avgPWR = lapPower.format("%d");
				avgPWR2 = npPower.format("%d");
				met1 = modePowerAvg[3];
				met2 = modePowerAvg[2];
				break;
			default: // 평균파워
				avgPWR = averagePower.format("%d");
				break;
		}

		var title1;
		switch(nsec) {
			case 3:		title1 = modePowerSS[1];	break;
			case 10:	title1 = modePowerSS[2];	break;
			case 30:	title1 = modePowerSS[3];	break;
			default:	title1 = modePowerSS[0];
		}
		var title2;
		switch(averageMode) {
			case 0:		title2 = modePowerAvg[0];	break;
			case 1:		title2 = modePowerAvg[1];	break;
			case 2:		title2 = modePowerAvg[2];	break;
			case 3:		title2 = modePowerAvg[3];	break;
			case 4:		title2 = modePowerAvg[4];	break;
			case 5:		title2 = modePowerAvg[5];	break;
			case 6:		title2 = modePowerAvg[6];	break;
			default:	title2 = "Avg";
		}
		var title;
		if (width==114 || width == 115 || width == 99) {
			title = title1;
		} else if ( field<2 ) {
			title = title1 + "/" + title2;
	        //if (showMaxPower) { title = title + "/" + "Max"; }
        } else {
			title = title1 + "/" + title2;
		}
		title1 = null;
		title2 = null;

		var ttv;	

		//////////////////////////////////////////////////////////////////////////////////////////////////////
		// 평균, 단위, 라벨
		dc.setColor(colors[:color], colors[:background]);
		var label = pwrMode == MODE_AVERAGE ? labelAvg : labelPersonal;
		switch(field) {
			// Full
			case 0:
				dc.drawText(width*0.5, loc[1], fnt[3], title, Graphics.TEXT_JUSTIFY_CENTER);
				if ( height > 100 ) {
					dc.drawText(loc[6], loc[7] + h_val, fnt[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
					dc.drawText(loc[4], loc[5] + h_val, fnt[0], avgPWR, Graphics.TEXT_JUSTIFY_RIGHT);
					dc.drawText(loc[10], loc[7] + h_val, fnt[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
					dc.drawText(loc[10], loc[5] + h_val, fnt[3], label, Graphics.TEXT_JUSTIFY_LEFT);
					if (ShowTraining) { drawWorkoutFullTxt(dc); }
				} else {
					dc.drawText(loc[6], loc[7], fnt[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
					dc.drawText(loc[4], loc[5], fnt[0], avgPWR, Graphics.TEXT_JUSTIFY_RIGHT);
					dc.drawText(loc[10], loc[7], fnt[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
					dc.drawText(loc[10], loc[5], fnt[3], label, Graphics.TEXT_JUSTIFY_LEFT);
					if (ShowTraining) { drawWorkoutTxt(dc); }
				}
				break;
			// Full x 2 
			case 1:
				if ( height > 100 ) {
					dc.drawText(width*0.34, loc[1], fnt[3], title, Graphics.TEXT_JUSTIFY_CENTER);
					dc.drawText(loc[6], loc[7] + h_val, fnt[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
					dc.drawText(loc[8], loc[11] + h_val, fnt[0], avgPWR, RIGHTV);
					dc.drawText(loc[8], loc[9] + h_val, fnt[0], avgPWR2, RIGHTV);
					dc.drawText(loc[10], loc[11] + h_val, fnt[3], met1, LEFTV);
					dc.drawText(loc[10], loc[9] + h_val, fnt[3], met2, LEFTV);
					if (ShowTraining) { drawWorkoutFullTxt(dc); }
				} else {
					dc.drawText(width*0.4, loc[1], fnt[3], title, Graphics.TEXT_JUSTIFY_CENTER);
					dc.drawText(loc[6], loc[7], fnt[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
					dc.drawText(loc[8], loc[11], fnt[1], avgPWR, RIGHTV);
					dc.drawText(loc[8], loc[9], fnt[1], avgPWR2, RIGHTV);
					dc.drawText(loc[10], loc[11], fnt[3], met1, LEFTV);
					dc.drawText(loc[10], loc[9], fnt[3], met2, LEFTV);
					if (ShowTraining) { drawWorkoutTxt(dc); }
				}
				break;
			// Half Big
			case 2:
				dc.drawText(width * 0.5 + PZlocX, loc[1], fnt[3], title, Graphics.TEXT_JUSTIFY_CENTER);
				dc.drawText(loc[8], loc[9], fnt[1], avgPWR, Graphics.TEXT_JUSTIFY_RIGHT);
				dc.drawText(loc[12], loc[11], fnt[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
				break;
			// Half Big x 2
			case 3:
				dc.drawText(loc[8], loc[9], fnt[1], avgPWR, RIGHTV);
				dc.drawText(loc[8], loc[11], fnt[1], avgPWR2, RIGHTV);
				break;
			// Half Small
			case 4:
				dc.drawText(width * 0.5 + PZlocX, loc[1], fnt[3], title, Graphics.TEXT_JUSTIFY_CENTER);
				dc.drawText(loc[6], loc[7], fnt[2], avgPWR, Graphics.TEXT_JUSTIFY_RIGHT);
				dc.drawText(loc[10], loc[11], fnt[3], metric, Graphics.TEXT_JUSTIFY_LEFT);
				break;
			// Half Small x 2
			case 5:
			default:
				dc.drawText(width * 0.5 + PZlocX, loc[1], fnt[3], title, Graphics.TEXT_JUSTIFY_CENTER);
				dc.drawText(loc[6], loc[7], fnt[2], avgPWR, Graphics.TEXT_JUSTIFY_RIGHT);
				dc.drawText(loc[6], loc[11], fnt[2], avgPWR2, Graphics.TEXT_JUSTIFY_RIGHT);
		}
	}

	function normalizeArray() {
		var sumArray = 0.0;
		var maxAA = 0.0;
		var gridArray = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
		for (var inc_j = 0; inc_j < 7 ; inc_j++) {
			var pwrData = pwrArray[inc_j].toFloat();
			sumArray += pwrData;
			gridArray[inc_j] = pwrData;
			if (pwrData>maxAA) { maxAA = pwrData; }
		}
		if (maxAA == 0) { return pwrArray; }

		var maxGrid = loc[15];
		if (normalizeOn) {
			for (var inc_k = 0; inc_k < 7; inc_k++) {
				gridArray[inc_k] = pwrArray[inc_k] / maxAA * maxGrid;
			}
		}

		if (ShowTraining) {
			if (sumArray > 0) {
				for (var inc_k = 0; inc_k < 7; inc_k++) {
					pwrNArray[inc_k] = pwrArray[inc_k] / sumArray * 100.0f;
				}
			} 
		}
		return gridArray;
	}
		
    function pushArray(array, obj) as Array {
    	array.add(obj);
    	array = array.slice(1, null);
    	return array;
    }

    function meanArray(array) as Float {
    	var sizeArr = array.size();
    	var sumArr = 0.0f;
    	for (var inc = 0; inc < sizeArr; inc++) {
			if (array[inc] != null) {
				sumArr += array[inc];
			} else {
				sumArr = 0.0f;
			}
    	}
		return sumArr/sizeArr;
    }

    function meanNPArray(aPow30s) as Numeric {
    	var calPower;
    	switch(count_n) {
    		case 0:
    			calPower = aPow30s;
    			break;
    		default:
    			var oldF = (count_n-1.0)/count_n;
    			var newF = 1.0/count_n;
				calPower = Math.pow(lastNPower,4) * oldF + Math.pow(aPow30s,4) * newF;
				calPower = Math.pow(calPower,0.25);
		}
		lastNPower = calPower;
    	count_n++;
    	return calPower;
    }
    
    function readModePower() {
    	modePowerSS[0] = loadResource(Rez.Strings.modeNone);
    	modePowerSS[1] = loadResource(Rez.Strings.mode3s);
    	modePowerSS[2] = loadResource(Rez.Strings.mode10s);
    	modePowerSS[3] = loadResource(Rez.Strings.mode30s);
    }
    
    function readModeAverage() {
    	modePowerAvg[0] = loadResource(Rez.Strings.modeAvg);;
    	modePowerAvg[1] = loadResource(Rez.Strings.modeMax);
    	modePowerAvg[2] = loadResource(Rez.Strings.modeNP);
    	modePowerAvg[3] = loadResource(Rez.Strings.modeLap);
    	modePowerAvg[4] = loadResource(Rez.Strings.modeAvgMax);
    	modePowerAvg[5] = loadResource(Rez.Strings.modeAvgNP);
    	modePowerAvg[6] = loadResource(Rez.Strings.modeLapNP);
    }
    
    function readWOlabel() {
    	WOlabel[0] = loadResource(Rez.Strings.lbNA);;
    	WOlabel[1] = loadResource(Rez.Strings.lbRECV);
    	WOlabel[2] = loadResource(Rez.Strings.lbPRMD);
    	WOlabel[3] = loadResource(Rez.Strings.lbPOL);
    	WOlabel[4] = loadResource(Rez.Strings.lbBASE);
    	WOlabel[5] = loadResource(Rez.Strings.lbHVLI);
    	WOlabel[6] = loadResource(Rez.Strings.lbBAL);
    	WOlabel[7] = loadResource(Rez.Strings.lbTEMPO);
    	WOlabel[8] = loadResource(Rez.Strings.lbSST);
    	WOlabel[9] = loadResource(Rez.Strings.lbRPT);
    	WOlabel[10] = loadResource(Rez.Strings.lbVO2MAX);
    	WOlabel[11] = loadResource(Rez.Strings.lbHIIT);
    	WOlabel[12] = loadResource(Rez.Strings.lbSPT);
    }

    function checkWorkout() {
    	if (pwrNArray[0] > 75) {
    		WOstate = 1;		// RECV (존1 75% 초과)
    	} else if (pwrNArray[0] > 25 && pwrNArray[1] > 25) {
    		WOstate = 4;		// BASE (존1, 존2 각각 25% 초과)
    	} else if (pwrNArray[0] > 5 && pwrNArray[1] > 5 && pwrNArray[2] > 5 && pwrNArray[3] > 5 && pwrNArray[4] > 2 && (pwrNArray[5] > 2 || pwrArray[5] > 30) && (pwrNArray[6] > 1 || pwrArray[6] > 3)) {
    		WOstate = 6;		// BAL (전 영역 5% 초과 또는 존6 30초 초과, 존7 3초 초과)
    	} else if (pwrNArray[1] > 60) {
    		WOstate = 5;		// HVLI (존2 60% 초과)
    	} else if (pwrNArray[1] > 20 && pwrNArray[2] > 20 && pwrNArray[3] > 20) {
    		WOstate = 2;		// PRMD (존2~존4 각각 20% 초과)
    	} else if (pwrNArray[1] > 20 && pwrNArray[4] > 20 && (pwrNArray[5] > 20 || pwrArray[5] > 30)) {
    		WOstate = 3;		// POL (존2,존5~존6 각각 20% 초과 또는 존6 30초 초과)
    	} else if (pwrNArray[2] > 25 && pwrArray[2] > 3600) {
    		WOstate = 7;		// TEMPO (존3 25% 초과 및 존3 1시간 초과)
    	} else if (pwrNArray[2] > 20 && pwrNArray[3] > 15) {
    		WOstate = 8;		// SST (존3~존4 각각 15% 초과)
    	} else if (pwrNArray[2] > 9 && pwrNArray[3] > 9 && pwrNArray[4] > 9 && (pwrNArray[5] > 9 || pwrArray[5] > 600)) {
    		WOstate = 9;		// RPT (존3~존6 각각 9% 초과거나 존6는 600초 초과일 경우)
    	} else if (pwrNArray[3] > 15 && pwrNArray[4] > 10 && pwrArray[4] > 1200) {
    		WOstate = 10;		// VO2MAX (존4, 존5 14% 초과 또는 존5 20분 이상 훈련)
    	} else if (pwrNArray[4] > 9 && (pwrNArray[5] > 5 || pwrArray[5] > 600)) {
    		WOstate = 11;		// HIIT(존5~존6 9% 또는 존6 600초 초과)
    	} else if (pwrNArray[6] > 70 || pwrArray[6] > 60) {
    		WOstate = 12;       // SPT (존7 70% 이상 또는 존7 60초 초과)
    	} else {
    		WOstate = 0; 
    	}
    }
    
    function drawWorkoutTxt(dc) {
    	var strWO;
    	checkWorkout();
    	switch(WOstate) {
    		case 1:
    			strWO = "RECV";
    			break;
    		case 2:
    			strWO = "PRMD";
    			break;
    		case 3:
    			strWO = "POL";
    			break;
    		case 4:
    			strWO = "BASE";
    			break;
    		case 5:
    			strWO = "HVLI";
    			break;
    		case 6:
    			strWO = "BAL";
    			break;
    		case 7:
    			strWO = "TEMPO";
    			break;
    		case 8:
    			strWO = "SST";
    			break;
    		case 9:
    			strWO = "RPT";
    			break;
    		case 10:
    			strWO = "VO2MAX";
    			break;
    		case 11:
    			strWO = "HIIT";
    			break;
    		case 12:
    			strWO = "SPT";
    			break;
    		default:
    			strWO = "N/A";
    	}  
    	dc.drawText(width * 0.98, height * 0.03, Graphics.FONT_MEDIUM, strWO, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    function drawWorkoutFullTxt(dc) {
    	var strWO;
    	checkWorkout();
    	strWO = WOlabel[WOstate];
    	/*
    	switch(WOstate) {
    		case 1:
    			strWO = WOlabel[1];
    			break;
    		case 2:
    			strWO = WOlabel[2];
    			break;
    		case 3:
    			strWO = WOlabel[3];
    			break;
    		case 4:
    			strWO = WOlabel[4];
    			break;
    		case 5:
    			strWO = WOlabel[5];
    			break;
    		case 6:
    			strWO = WOlabel[6];
    			break;
    		case 7:
    			strWO = WOlabel[7];
    			break;
    		case 8:
    			strWO = WOlabel[8];
    			break;
    		case 9:
    			strWO = WOlabel[9];
    			break;
    		case 10:
    			strWO = WOlabel[10];
    			break;
    		case 11:
    			strWO = WOlabel[11];
    			break;
    		case 12:
    			strWO = WOlabel[12];
    			break;
    		default:
    			strWO = WOlabel[0];
    	} 
    	*/ 
    	dc.drawText(width * 0.05, height * 0.52, Graphics.FONT_MEDIUM, strWO, Graphics.TEXT_JUSTIFY_LEFT);
    }
}