WITH ws_agg AS (
   SELECT
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_ship_mode_sk,
      ws_bill_cdemo_sk,
      SUM(ws_net_paid) AS total_net_paid,
      SUM(ws_quantity) AS total_quantity
   FROM web_sales
   WHERE ws_sales_price > 50
   GROUP BY ws_sold_date_sk, ws_sold_time_sk, ws_ship_mode_sk, ws_bill_cdemo_sk
),
joined AS (
   SELECT
      d.d_date,
      d.d_year,
      sm.sm_carrier,
      cd.cd_gender,
      t.t_hour,
      cp.cp_department,
      ws_agg.total_net_paid,
      ws_agg.total_quantity
   FROM ws_agg
   JOIN date_dim d ON ws_agg.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws_agg.ws_sold_time_sk = t.t_time_sk
   JOIN ship_mode sm ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_demographics cd ON ws_agg.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   WHERE d.d_year = 1998
     AND sm.sm_carrier = 'UPS'
     AND cd.cd_gender = 'M'
     AND t.t_hour >= 12
)
SELECT
   sm_carrier AS carrier,
   cp_department AS department,
   SUM(total_net_paid) AS sum_net_paid,
   SUM(total_quantity) AS sum_quantity,
   COUNT(*) AS transaction_groups
FROM joined
GROUP BY sm_carrier, cp_department
HAVING SUM(total_net_paid) > 1000
ORDER BY sum_net_paid DESC
LIMIT 100
