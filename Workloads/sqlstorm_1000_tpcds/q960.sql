WITH unified_sales AS (
   SELECT
       CAST('store' AS varchar) AS channel,
       ss_sold_date_sk AS date_sk,
       ss_item_sk AS item_sk,
       ss_store_sk AS store_sk,
       CAST(NULL AS integer) AS web_site_sk,
       CAST(NULL AS integer) AS call_center_sk,
       ss_net_paid AS net_paid,
       ss_net_profit AS net_profit,
       ss_ext_discount_amt AS discount
   FROM store_sales
   UNION ALL
   SELECT
       CAST('catalog' AS varchar) AS channel,
       cs_sold_date_sk AS date_sk,
       cs_item_sk AS item_sk,
       CAST(NULL AS integer) AS store_sk,
       CAST(NULL AS integer) AS web_site_sk,
       cs_call_center_sk AS call_center_sk,
       cs_net_paid AS net_paid,
       cs_net_profit AS net_profit,
       cs_ext_discount_amt AS discount
   FROM catalog_sales
   UNION ALL
   SELECT
       CAST('web' AS varchar) AS channel,
       ws_sold_date_sk AS date_sk,
       ws_item_sk AS item_sk,
       CAST(NULL AS integer) AS store_sk,
       ws_web_site_sk AS web_site_sk,
       CAST(NULL AS integer) AS call_center_sk,
       ws_net_paid AS net_paid,
       ws_net_profit AS net_profit,
       ws_ext_discount_amt AS discount
   FROM web_sales
),
location_info AS (
   SELECT s_store_sk AS location_sk, CAST('store' AS varchar) AS location_type, s_state AS state FROM store
   UNION ALL
   SELECT web_site_sk AS location_sk, CAST('web' AS varchar) AS location_type, web_state AS state FROM web_site
   UNION ALL
   SELECT cc_call_center_sk AS location_sk, CAST('catalog' AS varchar) AS location_type, cc_state AS state FROM call_center
),
sales_with_dim AS (
   SELECT
       us.channel,
       d.d_year,
       d.d_quarter_name,
       i.i_brand,
       COALESCE(l.state, 'UNKNOWN') AS state,
       us.net_paid,
       us.net_profit,
       us.discount
   FROM unified_sales us
   LEFT JOIN date_dim d ON us.date_sk = d.d_date_sk
   LEFT JOIN item i ON us.item_sk = i.i_item_sk
   LEFT JOIN location_info l ON (
       (us.channel = 'store' AND us.store_sk = l.location_sk)
       OR (us.channel = 'web' AND us.web_site_sk = l.location_sk)
       OR (us.channel = 'catalog' AND us.call_center_sk = l.location_sk)
   )
   WHERE d.d_year BETWEEN 2020 AND 2022
),
brand_quarter_sales AS (
   SELECT
       channel,
       d_year,
       d_quarter_name,
       i_brand,
       SUM(net_paid) AS total_net_paid,
       SUM(net_profit) AS total_net_profit,
       SUM(discount) AS total_discount,
       COUNT(*) AS transaction_count
   FROM sales_with_dim
   GROUP BY channel, d_year, d_quarter_name, i_brand
),
brand_quarter_rank AS (
   SELECT
       *,
       RANK() OVER (PARTITION BY channel, d_year, d_quarter_name ORDER BY total_net_profit DESC) AS profit_rank,
       SUM(total_net_profit) OVER (PARTITION BY channel, d_year, d_quarter_name) AS sum_profit_per_qtr,
       total_net_profit / SUM(total_net_profit) OVER (PARTITION BY channel, d_year, d_quarter_name) AS profit_share,
       AVG(total_net_profit) OVER (PARTITION BY i_brand ORDER BY d_year, d_quarter_name ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS moving_avg_profit_4q
   FROM brand_quarter_sales
)
SELECT
   channel,
   d_year,
   d_quarter_name,
   i_brand,
   total_net_paid,
   total_net_profit,
   total_discount,
   transaction_count,
   profit_rank,
   profit_share,
   moving_avg_profit_4q,
   (SELECT AVG(total_net_profit) FROM brand_quarter_sales bq WHERE bq.i_brand = bq_outer.i_brand) AS avg_brand_profit_overall
FROM brand_quarter_rank bq_outer
WHERE profit_rank <= 10
ORDER BY channel, d_year, d_quarter_name, profit_rank
