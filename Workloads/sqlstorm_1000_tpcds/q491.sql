WITH unified_sales AS (
 SELECT
   ss.ss_sold_date_sk AS date_sk,
   ss.ss_store_sk AS location_sk,
   'store' AS channel,
   ss.ss_item_sk AS item_sk,
   ss.ss_quantity AS quantity,
   ss.ss_net_paid AS net_paid,
   ss.ss_net_profit AS net_profit,
   ss.ss_promo_sk AS promo_sk
 FROM store_sales ss
 UNION ALL
 SELECT
   cs.cs_sold_date_sk,
   cs.cs_call_center_sk,
   'catalog',
   cs.cs_item_sk,
   cs.cs_quantity,
   cs.cs_net_paid,
   cs.cs_net_profit,
   cs.cs_promo_sk
 FROM catalog_sales cs
 UNION ALL
 SELECT
   ws.ws_sold_date_sk,
   ws.ws_web_site_sk,
   'web',
   ws.ws_item_sk,
   ws.ws_quantity,
   ws.ws_net_paid,
   ws.ws_net_profit,
   ws.ws_promo_sk
 FROM web_sales ws
),
location_dim AS (
 SELECT s.s_store_sk AS location_sk, s.s_store_id AS location_id, s.s_state AS state FROM store s
 UNION ALL
 SELECT cc.cc_call_center_sk, cc.cc_call_center_id, cc.cc_state FROM call_center cc
 UNION ALL
 SELECT ws.web_site_sk, ws.web_site_id, ws.web_state FROM web_site ws
),
sales_agg AS (
 SELECT
   d.d_year,
   d.d_month_seq,
   loc.state,
   i.i_category,
   i.i_class,
   i.i_brand,
   us.channel,
   SUM(us.quantity) AS total_quantity,
   SUM(us.net_paid) AS total_net_paid,
   SUM(us.net_profit) AS total_net_profit,
   COUNT(*) AS txn_count,
   SUM(CASE WHEN p.p_promo_id IS NOT NULL THEN 1 ELSE 0 END) AS promo_txn_count
 FROM unified_sales us
 JOIN date_dim d ON us.date_sk = d.d_date_sk
 LEFT JOIN location_dim loc ON us.location_sk = loc.location_sk
 LEFT JOIN item i ON us.item_sk = i.i_item_sk
 LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
 GROUP BY
   d.d_year,
   d.d_month_seq,
   loc.state,
   i.i_category,
   i.i_class,
   i.i_brand,
   us.channel
),
ranked AS (
 SELECT
   d_year,
   d_month_seq,
   state,
   i_category,
   channel,
   total_quantity,
   total_net_paid,
   total_net_profit,
   txn_count,
   promo_txn_count,
   ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, state, channel ORDER BY total_net_paid DESC) AS category_rank,
   SUM(total_net_paid) OVER (PARTITION BY d_year, d_month_seq, state, channel) AS state_total_net_paid
 FROM sales_agg
)
SELECT
 d_year,
 d_month_seq,
 state,
 i_category,
 channel,
 total_net_paid,
 total_net_profit,
 txn_count,
 promo_txn_count,
 category_rank,
 (total_net_paid / NULLIF(state_total_net_paid, 0)) * 100.0 AS pct_of_state_total_net_paid
FROM ranked
WHERE category_rank <= 3
ORDER BY d_year, d_month_seq, state, channel, category_rank
