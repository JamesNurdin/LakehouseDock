WITH sales_with_details AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_product_name,
        CONCAT(i.i_brand, ' ', i.i_product_name) AS brand_product,
        REGEXP_EXTRACT(i.i_item_desc, '(?i)(.*)premium(.*)', 1) AS premium_fragment,
        sm.sm_type,
        sm.sm_code,
        d.d_year,
        ca.ca_city
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '(?i)premium')
      AND sm.sm_code LIKE 'A%'
      AND ca.ca_city LIKE 'San%'
)
SELECT
    d_year,
    sm_type,
    brand_product,
    COUNT(DISTINCT cs_order_number) AS orders_cnt,
    SUM(cs_net_paid) AS total_net_paid,
    MAX(premium_fragment) AS example_premium_text
FROM sales_with_details s
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns r
    WHERE r.cr_order_number = s.cs_order_number
      AND r.cr_item_sk = s.cs_item_sk
)
GROUP BY d_year, sm_type, brand_product
HAVING SUM(cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
