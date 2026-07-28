WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_net_paid,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND regexp_like(c.c_first_name, '^A')
)
SELECT
    i.i_brand,
    d.d_year,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    regexp_extract(i.i_item_desc, '(\\w+)-\\w+', 1) AS desc_prefix,
    CONCAT(i.i_brand, '_', CAST(d.d_year AS VARCHAR)) AS brand_year_key
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND regexp_like(i.i_item_desc, '.*[0-9]{3}.*')
  AND wp.wp_url LIKE '%example.com/%'
  AND c.c_first_name LIKE 'A%'
GROUP BY
    i.i_brand,
    d.d_year,
    regexp_extract(i.i_item_desc, '(\\w+)-\\w+', 1),
    CONCAT(i.i_brand, '_', CAST(d.d_year AS VARCHAR))
ORDER BY total_net_paid DESC
LIMIT 100
