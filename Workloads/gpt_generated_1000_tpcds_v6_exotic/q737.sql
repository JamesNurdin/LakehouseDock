WITH recent_sales AS (
   SELECT ws.*, wp.wp_rec_start_date
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE wp.wp_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
)
SELECT ship_type,
       total_profit,
       overall_avg_profit
FROM (
   SELECT
       sm.sm_type AS ship_type,
       SUM(rs.ws_net_profit) AS total_profit,
       (SELECT AVG(ws_net_profit) FROM web_sales) AS overall_avg_profit
   FROM recent_sales rs
   JOIN ship_mode sm ON rs.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE sm.sm_carrier = 'UPS'
   GROUP BY sm.sm_type

   UNION ALL

   SELECT
       sm.sm_type AS ship_type,
       SUM(rs.ws_net_profit) AS total_profit,
       (SELECT AVG(ws_net_profit) FROM web_sales) AS overall_avg_profit
   FROM recent_sales rs
   JOIN ship_mode sm ON rs.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_demographics cd ON rs.ws_ship_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_gender = 'F'
     AND EXISTS (
         SELECT 1
         FROM household_demographics hd
         WHERE hd.hd_demo_sk = rs.ws_ship_hdemo_sk
           AND hd.hd_vehicle_count > 0
     )
   GROUP BY sm.sm_type
) AS combined
ORDER BY total_profit DESC
LIMIT 100
