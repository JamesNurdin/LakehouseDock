WITH sales AS (
    SELECT d.d_year,
           i.i_category,
           s.s_store_name AS sales_channel,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    UNION ALL
    SELECT d.d_year,
           i.i_category,
           wp.wp_type AS sales_channel,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    UNION ALL
    SELECT d.d_year,
           i.i_category,
           cc.cc_name AS sales_channel,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
)
SELECT d_year,
       i_category,
       sales_channel,
       COUNT(*) AS order_cnt,
       SUM(net_profit) AS total_profit,
       AVG(net_profit) AS avg_profit
FROM sales
WHERE d_year BETWEEN 1998 AND 2000
GROUP BY d_year, i_category, sales_channel
ORDER BY total_profit DESC
LIMIT 100
