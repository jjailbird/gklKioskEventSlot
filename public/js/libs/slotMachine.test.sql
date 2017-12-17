CREATE OR REPLACE PACKAGE "PKG_MEM_XMAS_KIOSK" AS

   /****************************************************************************************************
 1.기      능: PKG_MEMBER_KIOSK 내역
 2.최초작성일: 2017/12/14
 3.최초작성자: 정현덕
 4.기      타:

****************************************************************************************************/
  -----------------------------------------------------------------------------------------------------------------------
  -- 공통변수 선언
  -----------------------------------------------------------------------------------------------------------------------
  VG_MSG      VARCHAR2(200) ;  --
  VG_ERR_MSG  VARCHAR2(200) ;  --  오류메시지

  -----------------------------------------------------------------------------------------------------------------------
  -- P1. 고객 확인
  -----------------------------------------------------------------------------------------------------------------------
  PROCEDURE GET_VALID_USER(ARG_PATRON_NO    IN T_PATRON_CARD_ISSUE.FST_INS_USER_ID%TYPE,    
                           ARG_REMOTE_ADDR IN VARCHAR2,
                           RC_RTN_VAL     OUT VARCHAR2);
                           
  -----------------------------------------------------------------------------------------------------------------------
  -- P2. 참여가능회수 확인
  -----------------------------------------------------------------------------------------------------------------------
  PROCEDURE GET_EVENT_NUM(ARG_PATRON_NO    IN T_PATRON_CARD_ISSUE.FST_INS_USER_ID%TYPE,
                         ARG_REMOTE_ADDR IN VARCHAR2,
                         RC_INFO        OUT SYS_REFCURSOR);
  
  -----------------------------------------------------------------------------------------------------------------------
  -- P3. 금액결정/로그처리
  -----------------------------------------------------------------------------------------------------------------------
  PROCEDURE GET_PATRON_PRIZE(ARG_PATRON_NO    IN T_PATRON_CARD_ISSUE.FST_INS_USER_ID%TYPE,
                            ARG_REMOTE_ADDR IN VARCHAR2,
                            RC_INFO        OUT SYS_REFCURSOR);
  
  -----------------------------------------------------------------------------------------------------------------------
  -- P4. 프린트 완료 저장
  -----------------------------------------------------------------------------------------------------------------------
  PROCEDURE SET_PATRON_PRINT(ARG_PATRON_NO    IN T_PATRON_CARD_ISSUE.FST_INS_USER_ID%TYPE,
                             ARG_REMOTE_ADDR IN VARCHAR2,   
                             ARG_DM_START_NO IN T_FREE_COUPON_OUT.DM_START_NO%TYPE);
  
  -----------------------------------------------------------------------------------------------------------------------
  -- P5. 재출력
  -----------------------------------------------------------------------------------------------------------------------
  PROCEDURE GET_PRIZE_REPRINT(ARG_PATRON_NO    IN T_PATRON_CARD_ISSUE.FST_INS_USER_ID%TYPE,
                              ARG_REMOTE_ADDR IN VARCHAR2,
                              RC_INFO        OUT SYS_REFCURSOR);
end PKG_MEM_XMAS_KIOSK;


CREATE OR REPLACE PACKAGE BODY "PKG_MEM_XMAS_KIOSK" AS									
									
/****************************************************************************************************									
1.기      능: PKG_MEMBER_KIOSK 내역									
2.최초작성일: 2017/12/14									
3.최초작성자: 정현덕									
4.기      타:									
									
****************************************************************************************************/									
	-----------------------------------------------------------------------------------------------------------------------								
									
	-----------------------------------------------------------------------------------------------------------------------								
	PROCEDURE GET_VALID_USER(ARG_PATRON_NO   IN T_PATRON_CARD_ISSUE.FST_INS_USER_ID%TYPE,								
							 ARG_REMOTE_ADDR IN VARCHAR2,		
							 RC_RTN_VAL      OUT VARCHAR2) 		
	IS     								
									
		V_CNT                NUMBER(1) := 0;							
		V_CMS_TEAM_CD        VARCHAR2(4) := '';							
		V_PURPOSE_CD         VARCHAR2(5) := '';							
		V_TIME               NUMBER(2) := 0;   							
		V_START_DT           VARCHAR2(8);							
		V_END_DT             VARCHAR2(8); 							
		V_CARD_DEGREE        T_PATRON.CARD_DEGREE%TYPE;							
		V_JUNKET_CONTRACT_CD T_AGENT.JUNKET_CONTRACT_CD%TYPE;							
									
		USER_DEF_EXP EXCEPTION;							
									
	BEGIN  								
									
		IF ARG_PATRON_NO IS NULL OR Trim(ARG_PATRON_NO) = '' THEN							
			VG_ERR_MSG := 'Please! Swipe your player card.';						
			RAISE USER_DEF_EXP;						
		END IF;							
									
		SELECT COUNT(*)							
		INTO V_CNT							
		FROM T_PATRON T							
		WHERE T.PATRON_NO = ARG_PATRON_NO							
		  AND T.RECORD_ST = 'A';							
									
		IF V_CNT = 0 Then							
			VG_ERR_MSG := 'Invalid Card No.';						
			RAISE USER_DEF_EXP;						
		END IF;							
									
		BEGIN							
			SELECT CMS_TEAM_CD, PURPOSE_CD						
			INTO V_CMS_TEAM_CD, V_PURPOSE_CD						
			FROM T_KIOSK_ADDR						
			WHERE KIOSK_IP = ARG_REMOTE_ADDR						
			  AND KIOSK_CD = 'MEM';						
		EXCEPTION							
			WHEN NO_DATA_FOUND THEN						
			RC_RTN_VAL := 'NOTINSVS';						
		END; 							
									
		IF RC_RTN_VAL = 'NOTINSVS' THEN							
			RC_RTN_VAL := 'NOTINSVS';						
		ELSE  							
			SELECT TO_CHAR(SYSDATE, 'HH24') INTO V_TIME FROM DUAL;						
									
			IF V_CMS_TEAM_CD = 'CX' OR V_CMS_TEAM_CD = 'HT' THEN						
				BEGIN					
					SELECT START_DT, END_DT				
					INTO V_START_DT, V_END_DT				
					FROM C_FREE_COUPON_PURPOSE				
					WHERE RECORD_ST = 'A'				
					  AND FREE_COUPON_CD = '012'				
					  AND START_DT <= TO_CHAR(SYSDATE - 6 / 24, 'YYYYMMDD')				
					  AND END_DT >= TO_CHAR(SYSDATE - 6 / 24, 'YYYYMMDD')				
					  AND PURPOSE_CD = V_PURPOSE_CD				
					GROUP BY START_DT, END_DT				
					;				
				EXCEPTION					
					WHEN NO_DATA_FOUND THEN				
					RC_RTN_VAL := 'NOTINSVS';				
				END;					
									
				IF RC_RTN_VAL = 'NOTINSVS' THEN					
					RC_RTN_VAL := 'NOTINSVS';				
				ELSIF TO_CHAR(SYSDATE - 6 / 24, 'YYYYMMDD') < V_START_DT OR V_END_DT < TO_CHAR(SYSDATE - 6 / 24, 'YYYYMMDD') THEN					
					RC_RTN_VAL := 'NOTINSVS';				
				ELSIF 12 <= V_TIME AND V_TIME < 14 THEN					
					RC_RTN_VAL := 'BLOCK';				
				ELSIF 15 <= V_TIME AND V_TIME < 21 THEN					
					RC_RTN_VAL := 'BLOCK';				
				ELSIF (22 <= V_TIME AND V_TIME < 24) OR (00 <= V_TIME AND V_TIME < 11) THEN					
					RC_RTN_VAL := 'BLOCK';  				
				ELSE					
					SELECT T.CARD_DEGREE, S.JUNKET_CONTRACT_CD				
					INTO V_CARD_DEGREE, V_JUNKET_CONTRACT_CD				
					FROM T_PATRON T, T_AGENT S				
					WHERE T.PATRON_NO = ARG_PATRON_NO				
					  AND T.RECORD_ST = 'A'				
					  AND T.AGENT_NO = S.AGENT_NO(+);				
									
					IF TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') < '20111001060000' THEN				
						IF V_CARD_DEGREE NOT IN ('S') THEN			
							VG_ERR_MSG := 'Silver cards are available.';		
							RAISE USER_DEF_EXP;		
						END IF;			
					ELSE				
						IF V_CARD_DEGREE IN ('N', 'L') OR V_JUNKET_CONTRACT_CD = 'BP' THEN			
							VG_ERR_MSG := 'This card can not be used';		
							RAISE USER_DEF_EXP;		
						END IF;			
					END IF; 				
									
					IF V_CARD_DEGREE IN ('S','G') THEN				
						RC_RTN_VAL := 'Y';			
					ELSE				
						RC_RTN_VAL := 'N';			
					END IF;				
				END IF;					
				ELSE					
					RC_RTN_VAL := 'NOTINSVS';				
			END IF;						
		END IF; 							
									
	EXCEPTION								
		WHEN USER_DEF_EXP THEN							
			RAISE_APPLICATION_ERROR(-20001, VG_ERR_MSG);						
		WHEN OTHERS THEN							
			RAISE_APPLICATION_ERROR(-20002, '[Error]' || SQLERRM);      						
									
	END GET_VALID_USER;   								
									
	-----------------------------------------------------------------------------------------------------------------------								
									
	-----------------------------------------------------------------------------------------------------------------------								
	PROCEDURE GET_EVENT_NUM(ARG_PATRON_NO   IN T_PATRON_CARD_ISSUE.FST_INS_USER_ID%TYPE,								
							ARG_REMOTE_ADDR IN VARCHAR2,		
							RC_INFO         OUT SYS_REFCURSOR) 		
	IS								
									
		V_DT VARCHAR2(8);							
		V_START_TM VARCHAR2(8);							
		V_END_TM VARCHAR2(8);							
									
		USER_DEF_EXP EXCEPTION;							
									
	BEGIN   								
									
		SELECT TO_CHAR(SYSDATE, 'YYYYMMDD')							
		INTO V_DT							
		FROM DUAL;							
  									
		SELECT CASE WHEN TO_CHAR(SYSDATE, 'HH24MISS') BETWEEN '110000' AND '120000' THEN '060000'							
		            WHEN TO_CHAR(SYSDATE, 'HH24MISS') BETWEEN '160000' AND '170000' THEN '110000'							
		            WHEN TO_CHAR(SYSDATE, 'HH24MISS') BETWEEN '210000' AND '220000' THEN '160000'							
		            ELSE '999999'							
		        END START_TM							
		     , CASE WHEN TO_CHAR(SYSDATE, 'HH24MISS') BETWEEN '110000' AND '120000' THEN '110000'							
		            WHEN TO_CHAR(SYSDATE, 'HH24MISS') BETWEEN '160000' AND '170000' THEN '160000'							
		            WHEN TO_CHAR(SYSDATE, 'HH24MISS') BETWEEN '210000' AND '220000' THEN '210000'							
		            ELSE '999999'							
		        END END_TM							
		INTO V_START_TM, V_END_TM							
		FROM DUAL;							
									
		DBMS_OUTPUT.PUT_LINE('V_START_TM=>' || V_START_TM ||',' ||'V_END_TM=>' || V_END_TM);							
									
		OPEN RC_INFO FOR							
		SELECT							
			ARG_PATRON_NO PATRON_NO,						
			(SELECT PATRON_NM FROM T_PATRON WHERE PATRON_NO = ARG_PATRON_NO) PATRON_NM,						
		 	CASE						
			    WHEN COMP_AMT BETWEEN 1000 AND 1999 THEN 1						
			    WHEN COMP_AMT BETWEEN 2000 AND 3999 THEN 2						
			    WHEN COMP_AMT BETWEEN 4000 AND 7999 THEN 3						
			    WHEN COMP_AMT BETWEEN 8000 AND 14999 THEN 4						
			    WHEN COMP_AMT BETWEEN 15000 AND 29999 THEN 5						
			    WHEN COMP_AMT BETWEEN 30000 AND 49999 THEN 6						
			    WHEN COMP_AMT >= 50000 THEN 7						
			    ELSE 0						
		    END CHANCE_CNT							
		FROM (							
				 SELECT NVL(SUM(COMP_AMT), 0) COMP_AMT					
			     FROM T_PATRON_GAME_ACTIVITY						
			     WHERE PATRON_NO = ARG_PATRON_NO						
			       AND RECORD_ST = 'A'						
			       AND INPUT_TM BETWEEN V_DT || V_START_TM AND V_DT || V_END_TM						
		     );    							
									
	EXCEPTION								
		WHEN USER_DEF_EXP THEN							
			RAISE_APPLICATION_ERROR(-20001, VG_ERR_MSG);						
		WHEN OTHERS THEN							
			RAISE_APPLICATION_ERROR(-20002, '[Error]' || SQLERRM);      						
									
	END GET_EVENT_NUM;                         								
									
	-----------------------------------------------------------------------------------------------------------------------								
    -- P3. 금액결정/로그처리									
    -----------------------------------------------------------------------------------------------------------------------									
    PROCEDURE GET_PATRON_PRIZE(ARG_PATRON_NO   IN T_PATRON_CARD_ISSUE.FST_INS_USER_ID%TYPE,									
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
	 								
	-----------------------------------------------------------------------------------------------------------------------								
									
	-----------------------------------------------------------------------------------------------------------------------								
	PROCEDURE SET_PATRON_PRINT(ARG_PATRON_NO   IN T_PATRON_CARD_ISSUE.FST_INS_USER_ID%TYPE,								
							   ARG_REMOTE_ADDR IN VARCHAR2,  		
							   ARG_DM_START_NO IN T_FREE_COUPON_OUT.DM_START_NO%TYPE)		
	IS 								
		V_TEAM_CD        VARCHAR2(4);							
	    V_PURPOSE_CD     VARCHAR2(5);								
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
		  AND KIOSK_CD = 'MEM'							
		;							
		  							
		UPDATE T_EVENT_KIOSK_LOG_NEW							
		SET PRINT_YN = 'Y'							
		WHERE DM_START_NO = ARG_DM_START_NO							
		  AND PATRON_NO = ARG_PATRON_NO							
		  AND PURPOSE_CD = V_PURPOSE_CD							
	    ;								
	    								
	EXCEPTION								
		WHEN USER_DEF_EXP THEN							
			RAISE_APPLICATION_ERROR(-20001, VG_ERR_MSG);						
		WHEN OTHERS THEN							
			RAISE_APPLICATION_ERROR(-20002, '[Error]' || SQLERRM);						
	END SET_PATRON_PRINT;    						   		
									
	-----------------------------------------------------------------------------------------------------------------------								
									
	-----------------------------------------------------------------------------------------------------------------------								
	PROCEDURE GET_PRIZE_REPRINT(ARG_PATRON_NO   IN T_PATRON_CARD_ISSUE.FST_INS_USER_ID%TYPE,								
								ARG_REMOTE_ADDR IN VARCHAR2,	
								RC_INFO         OUT SYS_REFCURSOR)	
	IS 								
		V_TEAM_CD        VARCHAR2(4);							
	    V_PURPOSE_CD     VARCHAR2(5);								
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
		  AND KIOSK_CD = 'MEM'							
		;  							
									
		OPEN RC_INFO FOR							
		SELECT							
			A.PATRON_NO,						
			(SELECT PATRON_NM FROM T_PATRON WHERE PATRON_NO = A.PATRON_NO) PATRON_NM,						
			A.LOG_DT, --로그일시						
			NVL(TO_CHAR(B.FREE_COUPON_AMT, 'L999,999,999,999'),0) FREE_COUPON_AMT, -- 금액						
			A.PRINT_YN, --출력여부						
			TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') START_DT,						
			TO_CHAR(TO_DATE(B.EXPIRE_DT,'YYYYMMDD'), 'YYYY-MM-DD')||' 06:00:00'END_DT,						
			B.DM_START_NO --바코드 번호						
		FROM T_EVENT_KIOSK_LOG_NEW A, T_FREE_COUPON_OUT B							
		WHERE A.PURPOSE_CD = V_PURPOSE_CD							
		  AND A.PATRON_NO = ARG_PATRON_NO							
		  AND A.PURPOSE_CD = B.PURPOSE_CD(+)							
		  AND A.PATRON_NO = B.PATRON_NO(+)							
		  AND A.DM_START_NO = B.DM_START_NO(+)							
		;							
		              							
	EXCEPTION								
		WHEN USER_DEF_EXP THEN							
			RAISE_APPLICATION_ERROR(-20001, VG_ERR_MSG);						
		WHEN OTHERS THEN							
			RAISE_APPLICATION_ERROR(-20002, '[Error]' || SQLERRM);						
	END GET_PRIZE_REPRINT;								
END PKG_MEM_XMAS_KIOSK;									