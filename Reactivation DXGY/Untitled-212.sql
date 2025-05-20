
-- Reactivation Results 
SET start_date = TO_DATE('2025-04-11');
SET comms_date = TO_DATE('2025-04-11');
SET end_date = DATEADD(DAY, 14, $start_date);
SET country1 = 'UK';
SET country2 = 'Ireland';

SELECT 
  A.DRIVER_ID,
  CLUSTER_NAME AS Cluster,
  CITY_NAME AS City,
  COUNT(OA_STATUS) ORDER_COUNT,
  SUM(CASE WHEN OA_STATUS = 'DELIVERED' AND TO_DATE(LOCAL_TIME_OA_CREATED_AT) BETWEEN $start_date AND DATEADD(DAY, (7 - DAYOFWEEK($start_date)), $start_date) THEN 1 ELSE 0 END) AS Orders_Week_1,
  SUM(CASE WHEN OA_STATUS = 'DELIVERED' AND TO_DATE(LOCAL_TIME_OA_CREATED_AT) BETWEEN DATEADD(DAY, (8 - DAYOFWEEK($start_date)), $start_date) AND DATEADD(DAY, (14 - DAYOFWEEK($start_date)), $start_date) THEN 1 ELSE 0 END) AS Orders_Week_2,
  SUM(CASE WHEN OA_STATUS = 'DELIVERED' AND TO_DATE(LOCAL_TIME_OA_CREATED_AT) BETWEEN DATEADD(DAY, (15 - DAYOFWEEK($start_date)), $start_date) AND $end_date THEN 1 ELSE 0 END) AS Orders_Week_3,
  CASE WHEN A.DRIVER_ID IN
    (SELECT driver_id
        FROM braze.rider_engagement
        WHERE ((( sent_at  ) >= ((CONVERT_TIMEZONE('Europe/London', 'UTC', CAST(TO_TIMESTAMP($comms_date) AS TIMESTAMP_NTZ)))) 
        AND sent_at < ((CONVERT_TIMEZONE('Europe/London', 'UTC', CAST(DATEADD('day', 1, TO_TIMESTAMP($comms_date)) AS TIMESTAMP_NTZ)))))) 
        AND campaign_canvas_name = 'rid-multi-reac-rec-gen-global-all-all-week45-20241106-reactivationautomation' 
        AND canvas_step_name = 'Email_1_Awareness'
        ) THEN 1 ELSE 0 END AS In_Comms

FROM production.denormalised.denormalised_assignment A
  WHERE COUNTRY_NAME IN ('UK', 'Ireland')
  AND OA_STATUS = 'DELIVERED'  
  AND TO_DATE(LOCAL_TIME_OA_CREATED_AT) BETWEEN $start_date AND $end_date
  AND A.DRIVER_ID IS NOT NULL
  AND A.DRIVER_ID IN
    (
'106390','505713','849881','934540','929023','940260','922071','758632','934401','795804','934617','843983','695424','944246','934726','505525','417317','900354','944148','886855','697658','879482','175548','926218','979392','616815','944845','829383','404096','471105','523572','200440','675381','850164','939888','811340','959681','617326','931442','940141','688207','836929','694661','814729','932653','939889','497003','782239','863716','917121','783400','623310','864960','837777','878699','745115','949024','455809','873527','927181','225373','948455','558869','546019','927935','938134','934145','462115','908205','940391','849786','450554','586436','935359','430713','964470','965251','854144','932956','781277','878550','381418','969328','773001','936429','976208','748880','394458','929840','938694','600394','182757','969060','844523','976210','976774','979925','144989','775592','117296','956776','355307','938565','848518','571979','178883','925982','932795','343000','770604','929999','646336','950700','346267','544298','829117','340871','931331','422098','938401','906414','879322','571681','946153','821606','828535','846721','334278','397703','357645','963288','481727','942341','425864','749512','817942','954222','340894','935173','822307','845380','749505','168384','878843','733547','828501','846472','929981','963742','433264','532515','827658','923870','931624','562468','672212','863724','342827','698832','491446','528197','936858','669548','410379','408141','811201','944439','934270','939135','546690','873845','406611','938513','508649','946950','947626','807924','818962','869476','935697','677054','977889','696818','793726'                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
    )   
GROUP BY 
  A.DRIVER_ID, CITY_NAME, CLUSTER_NAME, In_Comms
ORDER BY 
  ORDER_COUNT DESC, A.DRIVER_ID, CITY_NAME, CLUSTER_NAME
;  






















