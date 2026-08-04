WITH a AS (
   SELECT cr.cr_order_number AS order_key,
          cr.cr_net_loss      AS net_loss,
          hd_refunded.hd_vehicle_count AS vehicle_cnt,
          r1.r_reason_desc   AS reason_desc
   FROM catalog_returns cr
   JOIN time_dim t1
     ON cr.cr_returned_time_sk = t1.t_time_sk
   JOIN reason r1
     ON cr.cr_reason_sk = r1.r_reason_sk
   JOIN household_demographics hd_refunded
     ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
   JOIN household_demographics hd_returning
     ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
   WHERE r1.r_reason_id = (SELECT MIN(r_reason_id) FROM reason)
),
 b AS (
   SELECT sr.sr_ticket_number AS order_key,
          sr.sr_net_loss       AS net_loss,
          hd_store.hd_vehicle_count AS vehicle_cnt,
          r2.r_reason_desc    AS reason_desc
   FROM store_returns sr
   JOIN time_dim t2
     ON sr.sr_return_time_sk = t2.t_time_sk
   JOIN reason r2
     ON sr.sr_reason_sk = r2.r_reason_sk
   JOIN household_demographics hd_store
     ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
   WHERE r2.r_reason_desc LIKE '%price%'
),
 c AS (
   SELECT ws.ws_order_number AS order_key,
          ws.ws_net_profit   AS net_loss,
          hd_bill.hd_vehicle_count AS vehicle_cnt,
          'Web Sale' AS reason_desc
   FROM web_sales ws
   JOIN time_dim t3
     ON ws.ws_sold_time_sk = t3.t_time_sk
   JOIN household_demographics hd_bill
     ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN household_demographics hd_ship
     ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
   WHERE ws.ws_net_paid > 0
)
SELECT order_key,
       SUM(net_loss)        AS total_loss,
       AVG(vehicle_cnt)     AS avg_vehicle_cnt,
       COUNT(DISTINCT reason_desc) AS distinct_reasons
FROM (
   (SELECT order_key, net_loss, vehicle_cnt, reason_desc FROM a
    UNION
    SELECT order_key, net_loss, vehicle_cnt, reason_desc FROM b)
   EXCEPT
   SELECT order_key, net_loss, vehicle_cnt, reason_desc FROM c
) AS diff
GROUP BY order_key
ORDER BY total_loss DESC
LIMIT 100
