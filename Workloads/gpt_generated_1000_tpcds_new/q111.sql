WITH item_desc_stats AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_item_desc,
        regexp_extract(i.i_item_desc, '(\\d+)-([A-Z]+)', 1) AS numeric_part,
        regexp_extract(i.i_item_desc, '(\\d+)-([A-Z]+)', 2) AS alpha_part,
        length(i.i_item_desc) AS desc_len
    FROM item i
    WHERE regexp_like(i.i_item_desc, '\\d+-[A-Z]+')
)
SELECT
    d.d_year,
    sm.sm_type,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_quantity) AS avg_quantity,
    concat(i_desc.i_product_name, ' - ', CAST(d.d_year AS varchar)) AS product_year,
    substring(ca.ca_county, 1, 10) AS county_prefix
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item_desc_stats i_desc ON cs.cs_item_sk = i_desc.i_item_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
CROSS JOIN (VALUES (0.0), (5.0), (10.0)) AS discount_thr(threshold)
WHERE i_desc.alpha_part LIKE 'A%'
  AND ca.ca_county LIKE '%County'
  AND cs.cs_ext_discount_amt >= discount_thr.threshold
  AND d.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
          AND cr.cr_return_quantity > 0
    )
GROUP BY d.d_year, sm.sm_type, i_desc.i_product_name, ca.ca_county, discount_thr.threshold
ORDER BY total_net_paid DESC
LIMIT 100
