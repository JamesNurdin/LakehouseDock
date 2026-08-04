WITH filtered_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_net_profit,
        i.i_category,
        i.i_product_name,
        i.i_brand,
        wp.wp_url,
        c.c_last_name
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE regexp_like(wp.wp_url, 'sports|outdoor')
      AND i.i_product_name LIKE '%Pro%'
      AND c.c_last_name LIKE 'S%'
)
SELECT
    i_category,
    i_brand,
    i_product_name,
    CONCAT(i_brand, ' - ', SUBSTRING(i_product_name, 1, 5)) AS brand_prefix,
    COUNT(*) AS sales_count,
    SUM(ws_net_profit) AS total_profit,
    CASE
        WHEN SUM(ws_net_profit) > 100000 THEN 'High'
        WHEN SUM(ws_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_level
FROM filtered_sales
GROUP BY i_category, i_brand, i_product_name
ORDER BY total_profit DESC
OFFSET 0
LIMIT 100
