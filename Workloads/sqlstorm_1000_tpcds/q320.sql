WITH sales AS (
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_item_sk AS item_sk,
           cs_call_center_sk AS location_sk,
           cs_net_profit AS net_profit,
           cs_quantity AS quantity,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk AS sold_date_sk,
           ss_item_sk AS item_sk,
           ss_store_sk AS location_sk,
           ss_net_profit AS net_profit,
           ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk AS sold_date_sk,
           ws_item_sk AS item_sk,
           ws_web_page_sk AS location_sk,
           ws_net_profit AS net_profit,
           ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales
)
SELECT
    d.d_year,
    i.i_category,
    COALESCE(s.s_store_name, cc.cc_name, wp.wp_url) AS location_name,
    SUM(sales.net_profit) AS total_profit,
    SUM(sales.quantity) AS total_quantity
FROM sales
JOIN date_dim d ON sales.sold_date_sk = d.d_date_sk
JOIN item i ON sales.item_sk = i.i_item_sk
LEFT JOIN store s ON sales.channel = 'store' AND sales.location_sk = s.s_store_sk
LEFT JOIN call_center cc ON sales.channel = 'catalog' AND sales.location_sk = cc.cc_call_center_sk
LEFT JOIN web_page wp ON sales.channel = 'web' AND sales.location_sk = wp.wp_web_page_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, i.i_category, COALESCE(s.s_store_name, cc.cc_name, wp.wp_url)
ORDER BY d.d_year, total_profit DESC
LIMIT 100
