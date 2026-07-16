WITH unified_sales AS (
   SELECT
     ss_sold_date_sk AS date_sk,
     ss_item_sk AS item_sk,
     ss_store_sk AS store_sk,
     CAST(NULL AS integer) AS web_page_sk,
     CAST(NULL AS integer) AS call_center_sk,
     ss_net_paid AS net_paid,
     ss_net_profit AS net_profit,
     'store' AS channel
   FROM store_sales
   UNION ALL
   SELECT
     ws_sold_date_sk,
     ws_item_sk,
     CAST(NULL AS integer) AS store_sk,
     ws_web_page_sk,
     CAST(NULL AS integer) AS call_center_sk,
     ws_net_paid,
     ws_net_profit,
     'web' AS channel
   FROM web_sales
   UNION ALL
   SELECT
     cs_sold_date_sk,
     cs_item_sk,
     CAST(NULL AS integer) AS store_sk,
     CAST(NULL AS integer) AS web_page_sk,
     cs_call_center_sk,
     cs_net_paid,
     cs_net_profit,
     'catalog' AS channel
   FROM catalog_sales
),
agg_sales AS (
   SELECT
     d.d_year,
     i.i_category,
     s.channel,
     SUM(s.net_paid) AS total_net_paid,
     SUM(s.net_profit) AS total_net_profit,
     COUNT(*) AS sales_cnt
   FROM unified_sales s
   JOIN date_dim d ON s.date_sk = d.d_date_sk
   JOIN item i ON s.item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY d.d_year, i.i_category, s.channel
)
SELECT
   d_year,
   i_category,
   channel,
   total_net_paid,
   total_net_profit,
   sales_cnt,
   RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS revenue_rank
FROM agg_sales
ORDER BY d_year, revenue_rank
