WITH base AS (
   SELECT
      cs.cs_sold_date_sk,
      cs.cs_call_center_sk,
      cc.cc_name,
      cc.cc_state,
      cc.cc_company_name,
      cc.cc_country,
      cs.cs_ship_mode_sk,
      sm.sm_type,
      sm.sm_code,
      cs.cs_ship_hdemo_sk,
      hd.hd_buy_potential,
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_net_paid_inc_ship,
      cs.cs_quantity,
      cr.cr_return_amount,
      cr.cr_return_ship_cost
   FROM catalog_sales cs
   JOIN catalog_returns cr
     ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN household_demographics hd
     ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
   WHERE cs.cs_net_paid_inc_ship BETWEEN 2000 AND 6000
     AND cs.cs_quantity >= 1
     AND cr.cr_return_ship_cost > 100
     AND cc.cc_state IN ('GA','NY')
     AND cc.cc_company_name LIKE 'pri%'
     AND cc.cc_country = 'United States'
     AND sm.sm_code = 'AIR'
     AND hd.hd_buy_potential = '1001-5000'
)
SELECT
   cc_name AS call_center_name,
   sm_type AS ship_type,
   hd_buy_potential,
   cs_sold_date_sk,
   SUM(cs_net_paid_inc_ship) AS total_net_paid_inc_ship,
   AVG(cr_return_amount) AS avg_return_amount,
   COUNT(DISTINCT cs_order_number) AS distinct_orders,
   MIN(cs_quantity) AS min_quantity,
   MAX(cs_quantity) AS max_quantity,
   SUM(SUM(cs_net_paid_inc_ship)) OVER (
       PARTITION BY cc_name
       ORDER BY cs_sold_date_sk
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
   ) AS running_total_net_paid
FROM base
GROUP BY
   cc_name,
   sm_type,
   hd_buy_potential,
   cs_sold_date_sk
ORDER BY total_net_paid_inc_ship DESC
LIMIT 100
