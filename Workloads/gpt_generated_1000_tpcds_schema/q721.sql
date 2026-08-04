WITH ws_sample AS (
   SELECT *
   FROM web_sales
   TABLESAMPLE BERNOULLI (10)   -- sample 10% of web_sales rows
),
joined AS (
   SELECT
       ws.ws_order_number,
       ws.ws_net_paid,
       ws.ws_net_profit,
       i.i_category        AS category,
       i.i_brand,
       t.t_hour,
       hd.hd_buy_potential,
       ib.ib_lower_bound,
       sm.sm_type,
       wp.wp_type,
       wsit.web_state,
       cs.cs_quantity,
       cp.cp_department,
       wr.wr_return_quantity,
       CASE
           WHEN hd.hd_buy_potential = '>10000' THEN 'High'
           WHEN hd.hd_buy_potential = '1001-5000' THEN 'Medium'
           ELSE 'Low'
       END AS buy_potential_segment
   FROM ws_sample ws
   JOIN item i               ON ws.ws_item_sk   = i.i_item_sk
   JOIN time_dim t           ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN customer c           ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN ship_mode sm         ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsit        ON ws.ws_web_site_sk = wsit.web_site_sk
   JOIN promotion p          ON ws.ws_promo_sk = p.p_promo_sk
   -- dimensions that belong to the other fact table are joined through shared keys
   JOIN catalog_sales cs     ON cs.cs_item_sk = i.i_item_sk
   JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN web_returns wr  ON wr.wr_order_number = ws.ws_order_number
   WHERE t.t_hour BETWEEN 8 AND 18                     -- business‑hour filter
     AND i.i_category = 'Electronics'                 -- narrow to one category
     AND ib.ib_lower_bound >= 40000                   -- mid‑high income band
     AND wsit.web_state = 'CA'                        -- geographic filter
     AND sm.sm_type = 'AIR'                           -- ship mode filter
     AND wp.wp_type = 'HOME'                          -- page type filter
),
agg_all AS (
   SELECT
       web_state,
       category,
       buy_potential_segment,
       SUM(ws_net_paid)   AS total_net_paid,
       AVG(ws_net_profit) AS avg_profit,
       COUNT(DISTINCT ws_order_number) AS orders_cnt,
       MIN(ws_net_paid)   AS min_paid,
       MAX(ws_net_paid)   AS max_paid
   FROM joined
   GROUP BY ROLLUP (web_state, category, buy_potential_segment)
),
agg_low AS (
   SELECT
       web_state,
       category,
       buy_potential_segment,
       SUM(ws_net_paid)   AS total_net_paid,
       AVG(ws_net_profit) AS avg_profit,
       COUNT(DISTINCT ws_order_number) AS orders_cnt,
       MIN(ws_net_paid)   AS min_paid,
       MAX(ws_net_paid)   AS max_paid
   FROM joined
   WHERE buy_potential_segment = 'Low'
   GROUP BY ROLLUP (web_state, category, buy_potential_segment)
)
SELECT *
FROM agg_all
EXCEPT
SELECT *
FROM agg_low
ORDER BY total_net_paid DESC
OFFSET 0 FETCH NEXT 20 ROWS ONLY
