WITH sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_call_center_sk AS loc_sk,
           'call_center' AS loc_type,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_store_sk,
           'store',
           ss.ss_net_profit
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_web_page_sk,
           'web_page',
           ws.ws_net_profit
    FROM web_sales ws
)
SELECT d.d_year,
       s.loc_type,
       CASE
           WHEN s.loc_type = 'call_center' THEN cc.cc_name
           WHEN s.loc_type = 'store' THEN st.s_store_name
           WHEN s.loc_type = 'web_page' THEN wp.wp_url
           ELSE NULL
       END AS loc_name,
       SUM(s.net_profit) AS total_net_profit,
       COUNT(*) AS sales_count
FROM sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
LEFT JOIN call_center cc ON s.loc_type = 'call_center' AND s.loc_sk = cc.cc_call_center_sk
LEFT JOIN store st ON s.loc_type = 'store' AND s.loc_sk = st.s_store_sk
LEFT JOIN web_page wp ON s.loc_type = 'web_page' AND s.loc_sk = wp.wp_web_page_sk
WHERE d.d_year BETWEEN 1998 AND 2002
GROUP BY d.d_year,
         s.loc_type,
         CASE
             WHEN s.loc_type = 'call_center' THEN cc.cc_name
             WHEN s.loc_type = 'store' THEN st.s_store_name
             WHEN s.loc_type = 'web_page' THEN wp.wp_url
             ELSE NULL
         END
ORDER BY d.d_year,
         total_net_profit DESC
LIMIT 200
