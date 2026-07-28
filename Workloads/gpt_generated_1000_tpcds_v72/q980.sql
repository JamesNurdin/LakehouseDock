WITH product_strings AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1) AS numeric_part,
        CONCAT(i.i_brand, ' ', i.i_product_name) AS brand_product,
        i.i_item_desc
    FROM item i
    WHERE REGEXP_LIKE(i.i_item_desc, '[A-Z]{2}')
)
SELECT
    p.i_category,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
    MAX(p.numeric_part) AS example_numeric_part,
    MAX(p.brand_product) AS example_brand_product,
    MAX(SUBSTRING(wp.wp_url, 1, 10)) AS url_prefix
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN product_strings p ON ws.ws_item_sk = p.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 2020
  AND wp.wp_url LIKE 'http%'
GROUP BY p.i_category
HAVING SUM(ws.ws_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
