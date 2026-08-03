WITH ws_agg AS (
   SELECT
       ws_bill_hdemo_sk,
       COUNT(*) AS order_cnt,
       SUM(ws_net_paid) AS total_net_paid,
       AVG(ws_quantity) AS avg_quantity
   FROM web_sales
   WHERE ws_sold_time_sk BETWEEN 30000 AND 80000
     AND ws_ship_date_sk BETWEEN 2451500 AND 2453000
     AND ws_bill_cdemo_sk > 1200000
     AND ws_quantity > 0
   GROUP BY ws_bill_hdemo_sk
),
joined AS (
   SELECT
       h.hd_income_band_sk,
       h.hd_vehicle_count,
       h.hd_dep_count,
       a.order_cnt,
       a.total_net_paid,
       a.avg_quantity
   FROM ws_agg a
   JOIN household_demographics h
     ON a.ws_bill_hdemo_sk = h.hd_demo_sk
   WHERE h.hd_vehicle_count >= 0
     AND h.hd_income_band_sk IN (2, 6, 10, 18)
)
SELECT
   hd_income_band_sk,
   hd_vehicle_count,
   SUM(total_net_paid) AS sum_net_paid,
   AVG(order_cnt) AS avg_orders_per_demo,
   COUNT(*) AS demo_count
FROM joined
WHERE hd_dep_count <= 7
  AND hd_vehicle_count <> -1
GROUP BY hd_income_band_sk, hd_vehicle_count
HAVING SUM(total_net_paid) > 100000
ORDER BY sum_net_paid DESC
LIMIT 100
