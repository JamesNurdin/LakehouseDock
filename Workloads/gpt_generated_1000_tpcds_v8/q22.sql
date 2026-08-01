WITH senior_customers AS (
    SELECT COUNT(DISTINCT c.c_customer_sk) AS cnt
    FROM customer c
    WHERE c.c_birth_year BETWEEN 1950 AND 1960
)
SELECT
    cust.c_customer_id AS customer_id,
    d.d_date AS sales_date,
    cs.cs_ext_sales_price AS sales_amount,
    'catalog' AS sales_channel,
    sc.cnt AS senior_customers
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN inventory i ON i.inv_item_sk = cs.cs_item_sk AND i.inv_date_sk = d.d_date_sk
CROSS JOIN senior_customers sc
WHERE d.d_year = 2001
  AND cp.cp_type = 'electronics'
  AND i.inv_quantity_on_hand > 0

UNION ALL

SELECT
    cust.c_customer_id AS customer_id,
    d.d_date AS sales_date,
    ws.ws_ext_sales_price AS sales_amount,
    'web' AS sales_channel,
    sc.cnt AS senior_customers
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer cust ON ws.ws_bill_customer_sk = cust.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN inventory i ON i.inv_item_sk = ws.ws_item_sk AND i.inv_date_sk = d.d_date_sk
CROSS JOIN senior_customers sc
WHERE d.d_year = 2001
  AND wp.wp_image_count > 3
  AND i.inv_quantity_on_hand > 0

ORDER BY sales_amount DESC, sales_date
LIMIT 100
