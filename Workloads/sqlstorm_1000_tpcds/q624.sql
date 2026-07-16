WITH store_data AS (
    SELECT d.d_year,
           s.s_state AS region,
           SUM(ss.ss_net_paid) AS total_net_paid,
           SUM(ss.ss_net_profit) AS total_net_profit,
           COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY d.d_year, s.s_state
), web_data AS (
    SELECT d.d_year,
           wp.wp_type AS region,
           SUM(ws.ws_net_paid) AS total_net_paid,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(*) AS transaction_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY d.d_year, wp.wp_type
), catalog_data AS (
    SELECT d.d_year,
           cc.cc_state AS region,
           SUM(cs.cs_net_paid) AS total_net_paid,
           SUM(cs.cs_net_profit) AS total_net_profit,
           COUNT(*) AS transaction_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY d.d_year, cc.cc_state
)
SELECT sales_channel,
       d_year,
       region,
       total_net_paid,
       total_net_profit,
       transaction_count,
       SUM(total_net_paid) OVER (PARTITION BY sales_channel ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_paid
FROM (
    SELECT 'store' AS sales_channel, d_year, region, total_net_paid, total_net_profit, transaction_count
    FROM store_data
    UNION ALL
    SELECT 'web' AS sales_channel, d_year, region, total_net_paid, total_net_profit, transaction_count
    FROM web_data
    UNION ALL
    SELECT 'catalog' AS sales_channel, d_year, region, total_net_paid, total_net_profit, transaction_count
    FROM catalog_data
) AS combined
ORDER BY sales_channel, d_year, region
