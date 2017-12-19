 PROCEDURE GET_PATRON_PRIZE(ARG_PATRON_NO   IN CMS.T_PATRON_CARD_ISSUE.FST_INS_USER_ID%TYPE,											
                               ARG_REMOTE_ADDR IN VARCHAR2,											
                               RC_INFO         OUT SYS_REFCURSOR)											
    IS											
    											
	    V_TEAM_CD        VARCHAR2(4);										
	    V_PURPOSE_CD     VARCHAR2(5);										
	    										
	    V_CNT_0010       NUMBER(18) := 0;										
	    V_CNT_0020       NUMBER(18) := 0; 										
	    V_CNT_0030       NUMBER(18) := 0;										
	    V_CNT_0050       NUMBER(18) := 0;										
	    V_CNT_0100       NUMBER(18) := 0;										
	   										
        V_YN_0010        VARCHAR2(1):= 'N';											
        V_YN_0020        VARCHAR2(1):= 'N';											
        V_YN_0030        VARCHAR2(1):= 'N';											
        V_YN_0050        VARCHAR2(1):= 'N';											
        V_YN_0100        VARCHAR2(1):= 'N';											
        											
        V_UNIT_CD  		 VARCHAR2(4) := '0000';   									
        											
        V_DM_START_NO    VARCHAR2(19) := ''; 											
        											
        V_RD_NUM           NUMBER(18) := 0;   											
        											
		USER_DEF_EXP EXCEPTION;									
											
	BEGIN										
											
		IF ARG_PATRON_NO IS NULL OR Trim(ARG_PATRON_NO) = '' THEN									
			VG_ERR_MSG := 'Please! Swipe your player card.';								
			RAISE USER_DEF_EXP;								
		END IF;									
											
		SELECT CMS_TEAM_CD, PURPOSE_CD									
		INTO V_TEAM_CD, V_PURPOSE_CD									
		FROM T_KIOSK_ADDR									
		WHERE KIOSK_IP = ARG_REMOTE_ADDR									
		  AND KIOSK_CD = 'MEM';									
											
		DBMS_OUTPUT.PUT_LINE('금액결정 시작');									
		SELECT									
			COUNT(CASE WHEN UNIT_CD = '0010' THEN UNIT_CD END) UNIT_CD_0010,								
			COUNT(CASE WHEN UNIT_CD = '0020' THEN UNIT_CD END) UNIT_CD_0020,								
			COUNT(CASE WHEN UNIT_CD = '0030' THEN UNIT_CD END) UNIT_CD_0030,								
			COUNT(CASE WHEN UNIT_CD = '0050' THEN UNIT_CD END) UNIT_CD_0050,								
			COUNT(CASE WHEN UNIT_CD = '0100' THEN UNIT_CD END) UNIT_CD_0100								
		INTO V_CNT_0010,V_CNT_0020,V_CNT_0030,V_CNT_0050,V_CNT_0100									
		FROM T_FREE_COUPON_OUT									
		WHERE FREE_COUPON_CD = '012'									
		  AND PURPOSE_CD = V_PURPOSE_CD									
		  AND WORK_AREA_CD = V_TEAM_CD									
		; 									
											
		IF V_TEAM_CD = 'CX' THEN   									
			IF V_CNT_0100 < 5 THEN V_YN_0100 := 'Y'; END IF;								
			IF V_CNT_0050 < 10 THEN V_YN_0050 := 'Y'; END IF;								
			IF V_CNT_0030 < 20 THEN V_YN_0030 := 'Y'; END IF;								
			IF V_CNT_0020 < 25 THEN V_YN_0020 := 'Y'; END IF;								
			IF V_CNT_0010 < 40 THEN V_YN_0010 := 'Y'; END IF;								
											
			LOOP								
			EXIT WHEN (V_YN_0100 = 'N' AND 0 < V_RD_NUM AND V_RD_NUM <= 5)								
			          OR (V_YN_0050 = 'N' AND 5 < V_RD_NUM AND V_RD_NUM <= 15)								
			          OR (V_YN_0030 = 'N' AND 15 < V_RD_NUM AND V_RD_NUM <= 35)								
			          OR (V_YN_0020 = 'N' AND 35 < V_RD_NUM AND V_RD_NUM <= 60)								
			          OR (V_YN_0010 = 'N' AND 60 < V_RD_NUM AND V_RD_NUM <= 100)								
			          OR (100 < V_RD_NUM AND V_RD_NUM <= 200);								
 			SELECT CEIL(DBMS_RANDOM.VALUE(1,200)) NUM INTO V_RD_NUM FROM DUAL;								
			END LOOP;  								
											
			IF 0 < V_RD_NUM AND V_RD_NUM <= 5 THEN V_UNIT_CD := '0100';								
			ELSIF 5 < V_RD_NUM AND V_RD_NUM <= 15 THEN V_UNIT_CD := '0050';								
			ELSIF 15 < V_RD_NUM AND V_RD_NUM <= 35 THEN V_UNIT_CD := '0030';								
			ELSIF 35 < V_RD_NUM AND V_RD_NUM <= 60 THEN V_UNIT_CD := '0020';								
			ELSIF 60 < V_RD_NUM AND V_RD_NUM <= 100 THEN V_UNIT_CD := '0010';								
			ELSIF 100 < V_RD_NUM AND V_RD_NUM <= 200 THEN V_UNIT_CD := '0000';								
			END IF;								
											
		ELSIF V_TEAM_CD = 'HT' THEN									
			IF V_CNT_0100 < 10 THEN V_YN_0100 := 'Y'; END IF;								
			IF V_CNT_0050 < 15 THEN V_YN_0050 := 'Y'; END IF;								
			IF V_CNT_0030 < 30 THEN V_YN_0030 := 'Y'; END IF;								
			IF V_CNT_0020 < 35 THEN V_YN_0020 := 'Y'; END IF;								
			IF V_CNT_0010 < 60 THEN V_YN_0010 := 'Y'; END IF;								
											
			LOOP								
			EXIT WHEN (V_YN_0100 = 'N' AND 0 < V_RD_NUM AND V_RD_NUM <= 10)								
			          OR (V_YN_0050 = 'N' AND 10 < V_RD_NUM AND V_RD_NUM <= 25)								
			          OR (V_YN_0030 = 'N' AND 25 < V_RD_NUM AND V_RD_NUM <= 55)								
			          OR (V_YN_0020 = 'N' AND 55 < V_RD_NUM AND V_RD_NUM <= 90)								
			          OR (V_YN_0010 = 'N' AND 90 < V_RD_NUM AND V_RD_NUM <= 150)								
			          OR (150 < V_RD_NUM AND V_RD_NUM <= 300);								
 			SELECT CEIL(DBMS_RANDOM.VALUE(1,300)) NUM INTO V_RD_NUM FROM DUAL;								
			END LOOP;  								
											
			IF 0 < V_RD_NUM AND V_RD_NUM <= 10 THEN V_UNIT_CD := '0100';								
			ELSIF 10 < V_RD_NUM AND V_RD_NUM <= 25 THEN V_UNIT_CD := '0050';								
			ELSIF 25 < V_RD_NUM AND V_RD_NUM <= 55 THEN V_UNIT_CD := '0030';								
			ELSIF 55 < V_RD_NUM AND V_RD_NUM <= 90 THEN V_UNIT_CD := '0020';								
			ELSIF 90 < V_RD_NUM AND V_RD_NUM <= 150 THEN V_UNIT_CD := '0010';								
			ELSIF 150 < V_RD_NUM AND V_RD_NUM <= 300 THEN V_UNIT_CD := '0000';								
			END IF;								
		END IF;									
		DBMS_OUTPUT.PUT_LINE('금액결정 종료'); 									
		DBMS_OUTPUT.PUT_LINE('로그처리 시작');									
											
		SELECT 									
			V_TEAM_CD || TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS') ||	ROUND(DBMS_RANDOM.VALUE(100,999),0)							
		INTO V_DM_START_NO	    								
		FROM DUAL;									
											
		DBMS_OUTPUT.PUT_LINE('INSERT T_EVENT_KIOSK_LOG_NEW START');									
		INSERT INTO T_EVENT_KIOSK_LOG_NEW 									
		(									
			PURPOSE_CD,								
			LOG_SEQ,								
			PATRON_NO,								
			REG_DT,								
			KIOSK_IP,								
			LOG_DT,								
			UNIT_CD,								
			DM_START_NO								
		)									
		SELECT 									
			V_PURPOSE_CD PURPOSE_CD,								
			(SELECT NVL(MAX(LOG_SEQ),0) + 1 FROM T_EVENT_KIOSK_LOG_NEW WHERE PURPOSE_CD = V_PURPOSE_CD) LOG_SEQ,								
			ARG_PATRON_NO PATRON_NO,								
			SYSDATE REG_DT,								
			ARG_REMOTE_ADDR KIOSK_IP,								
			SYSDATE LOG_DT,								
			V_UNIT_CD UNIT_CD,								
			DECODE(V_UNIT_CD,'0000','',V_DM_START_NO) DM_START_NO 								
		FROM DUAL									
		;  									
		DBMS_OUTPUT.PUT_LINE('INSERT T_EVENT_KIOSK_LOG_NEW END');   									
											
		IF V_UNIT_CD <> '0000' THEN									
			DBMS_OUTPUT.PUT_LINE('INSERT T_FREE_COUPON_OUT START');     								
			INSERT INTO T_FREE_COUPON_OUT								
			(								
				TEAM_CD,							
				FREE_COUPON_CD,							
				OUT_SEQ,							
				PURPOSE_CD,							
				OUT_DT,							
				OUT_CNT,							
				EXPIRE_DT,							
				DM_START_NO,							
				RECORD_ST,							
				FST_INS_TIME,							
				UNIT_CD,  --C_FREE_COUPON_UNIT							
				PATRON_NO,							
				FREE_COUPON_AMT,  --C_FREE_COUPON_UNIT							
				WORK_AREA_CD, -- 'CSA', 디코드							
				MNG_TEAM_CD, --T_PATRON.MNG_TEAM_CD							
				CARD_DEGREE, --T_PATRON.CARD_DEGREE							
				MNG_OFFICE_CD, --T_PATRON.MNG_OFFICE_CD							
				PATRON_DEGREE --T_PATRON.PATRON_DEGREE							
			)								
			SELECT								
				DECODE(V_TEAM_CD,'CSA','CX','HSA','HT','LSA','LT') TEAM_CD,							
				'012' FREE_COUPON_CD,							
				(SELECT NVL(MAX(OUT_SEQ),0) FROM T_FREE_COUPON_OUT WHERE TEAM_CD = DECODE(V_TEAM_CD,'CSA','CX','HSA','HT','LSA','LT') AND FREE_COUPON_CD = '012') + ROWNUM OUT_SEQ,							
				V_PURPOSE_CD PURPOSE_CD,							
				TO_CHAR(SYSDATE - 6/24,'YYYYMMDD') OUT_DT,							
				1 OUT_CNT,							
				TO_CHAR(SYSDATE - 6/24+2,'YYYYMMDD') EXPIRE_DT,--다음날06시까지,							
				V_DM_START_NO DM_START_NO,							
				'A' RECORD_ST,							
				SYSDATE FST_INS_TIME,							
				V_UNIT_CD UNIT_CD,							
				ARG_PATRON_NO PATRON_NO,							
				(SELECT UNIT_AMT FROM C_FREE_COUPON_UNIT WHERE UNIT_CD = V_UNIT_CD) FREE_COUPON_AMT,							
				V_TEAM_CD WORK_AREA_CD,							
				(SELECT MNG_TEAM_CD FROM T_PATRON WHERE PATRON_NO = ARG_PATRON_NO) MNG_TEAM_CD,							
				(SELECT CARD_DEGREE FROM T_PATRON WHERE PATRON_NO = ARG_PATRON_NO) CARD_DEGREE,							
				(SELECT MNG_OFFICE_CD FROM T_PATRON WHERE PATRON_NO = ARG_PATRON_NO) MNG_OFFICE_CD,							
				(SELECT PATRON_DEGREE FROM T_PATRON WHERE PATRON_NO = ARG_PATRON_NO) PATRON_DEGREE							
			FROM DUAL								
			; 								
			DBMS_OUTPUT.PUT_LINE('INSERT T_FREE_COUPON_OUT END');								
											
			OPEN RC_INFO FOR								
			SELECT 								
 				PATRON_NO, --고객번호							
 				(SELECT PATRON_NM FROM T_PATRON WHERE PATRON_NO = ARG_PATRON_NO) PATRON_NM, --고객명							
 				TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') START_DT,							
 				TO_CHAR(TO_DATE(EXPIRE_DT,'YYYYMMDD'), 'YYYY-MM-DD')||' 06:00:00'END_DT,							
 				DM_START_NO, --바코드 번호							
 				NVL(TO_CHAR(FREE_COUPON_AMT, 'L999,999,999,999'),0) FREE_COUPON_AMT							
 			FROM T_FREE_COUPON_OUT								
 			WHERE FREE_COUPON_CD = '012' 								
 			  AND OUT_DT = TO_CHAR(SYSDATE - 6/24,'YYYYMMDD') 								
 			  AND RECORD_ST = 'A'								
 			  AND PATRON_NO = ARG_PATRON_NO  								
 			  AND PURPOSE_CD = V_PURPOSE_CD  								
 			  AND DM_START_NO = V_DM_START_NO								
			;								
		ELSE									
			OPEN RC_INFO FOR								
			SELECT 								
 				ARG_PATRON_NO PATRON_NO, --고객번호							
 				(SELECT PATRON_NM FROM T_PATRON WHERE PATRON_NO = ARG_PATRON_NO) PATRON_NM, --고객명							
 				'' START_DT,							
 				'' END_DT,							
 				'' DM_START_NO, --바코드 번호							
 				'0' FREE_COUPON_AMT							
 			FROM DUAL								
			;								
		END IF;									
		DBMS_OUTPUT.PUT_LINE('로그처리 종료'); 									
											
	EXCEPTION										
		WHEN USER_DEF_EXP THEN									
			RAISE_APPLICATION_ERROR(-20001, VG_ERR_MSG);								
		WHEN OTHERS THEN									
			RAISE_APPLICATION_ERROR(-20002, '[Error]' || SQLERRM);								
	END GET_PATRON_PRIZE;	