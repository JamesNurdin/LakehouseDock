WITH filtered_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_web_page_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_sold_time_sk
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE '%/sports/%'
)
SELECT
    i.i_brand AS brand,
    concat(i.i_brand, ' ', i.i_product_name) AS brand_product,
    substring(i.i_item_desc, 1, 20) AS short_desc,
    COUNT(*) AS sales_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_net_profit) AS avg_profit,
    CASE
        WHEN AVG(ws.ws_net_profit) > 100 THEN 'High'
        WHEN AVG(ws.ws_net_profit) > 0   THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM filtered_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
WHERE regexp_like(i.i_item_desc, '(?i)Pro|Plus')
  AND td.t_hour = 12
GROUP BY
    i.i_brand,
    concat(i.i_brand, ' ', i.i_product_name),
    substring(i.i_item_desc, 1, 20)
ORDER BY total_net_paid DESC
LIMIT 100
