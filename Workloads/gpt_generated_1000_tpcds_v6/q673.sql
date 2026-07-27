WITH catalog_agg AS (
   SELECT
       d.d_year,
       sm.sm_ship_mode_id,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(*) AS order_cnt
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2001
     AND sm.sm_carrier = 'FEDEX'
     AND i.i_formulation LIKE '%seashell%'
   GROUP BY d.d_year, sm.sm_ship_mode_id
),
web_agg AS (
   SELECT
       d.d_year,
       sm.sm_ship_mode_id,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(*) AS order_cnt
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN date_dim d2 ON wp.wp_creation_date_sk = d2.d_date_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2001
     AND sm.sm_carrier = 'FEDEX'
     AND i.i_formulation LIKE '%seashell%'
   GROUP BY d.d_year, sm.sm_ship_mode_id
),
combined AS (
   SELECT d_year, sm_ship_mode_id, total_profit, order_cnt FROM catalog_agg
   UNION ALL
   SELECT d_year, sm_ship_mode_id, total_profit, order_cnt FROM web_agg
)
SELECT
    d_year,
    sm_ship_mode_id,
    SUM(total_profit) AS sum_profit,
    AVG(total_profit) AS avg_profit,
    SUM(order_cnt) AS total_orders
FROM combined
GROUP BY d_year, sm_ship_mode_id
HAVING SUM(total_profit) > 10000
ORDER BY sum_profit DESC
LIMIT 100
