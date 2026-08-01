WITH morning_time AS (
    SELECT t_time_sk
    FROM time_dim
    WHERE t_sub_shift = 'morning'
)
SELECT sales_channel, item_sk, net_paid
FROM (
    SELECT 'catalog' AS sales_channel,
           cs.cs_item_sk AS item_sk,
           SUM(cs.cs_net_paid) AS net_paid
    FROM catalog_sales cs
    JOIN morning_time mt ON cs.cs_sold_time_sk = mt.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = 'Books'
    GROUP BY cs.cs_item_sk

    UNION ALL

    SELECT 'web' AS sales_channel,
           ws.ws_item_sk AS item_sk,
           SUM(ws.ws_net_paid) AS net_paid
    FROM web_sales ws
    JOIN morning_time mt ON ws.ws_sold_time_sk = mt.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'Content'
    GROUP BY ws.ws_item_sk
) AS combined_sales
ORDER BY net_paid DESC
LIMIT 100
