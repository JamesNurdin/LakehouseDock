WITH returns_agg AS (
   SELECT
       td.t_time AS time_of_day,
       sm.sm_type AS ship_mode_type,
       SUM(cr.cr_return_amount) AS total_amount,
       CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
   FROM catalog_returns cr
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   GROUP BY td.t_time, sm.sm_type
   HAVING SUM(cr.cr_return_amount) > 0
),
sales_agg AS (
   SELECT
       td.t_time AS time_of_day,
       sm.sm_type AS ship_mode_type,
       SUM(ws.ws_net_paid) AS total_amount,
       CASE WHEN SUM(ws.ws_net_paid) > 5000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
   FROM web_sales ws
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   GROUP BY td.t_time, sm.sm_type
   HAVING SUM(ws.ws_net_paid) > 0
)
SELECT *
FROM returns_agg
UNION ALL
SELECT *
FROM sales_agg
ORDER BY time_of_day, ship_mode_type, total_amount DESC
LIMIT 100
