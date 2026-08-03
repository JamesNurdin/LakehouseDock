WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_product_name,
        i_brand,
        i_color,
        regexp_extract(i_item_desc, '(\\w+)-\\w+', 1) AS extracted_term
    FROM tpcds.item
    WHERE regexp_like(i_item_desc, 'accessories')
      AND i_brand LIKE 'B%'
)
SELECT
    d.d_year,
    c.c_customer_id,
    i.i_brand,
    i.extracted_term,
    CONCAT(i.i_brand, '-', i.i_color) AS brand_color,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS orders_count
FROM filtered_items i
JOIN tpcds.catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE cs.cs_sold_date_sk IN (
    SELECT d2.d_date_sk
    FROM tpcds.date_dim d2
    WHERE d2.d_year = 2001
)
  AND EXISTS (
    SELECT 1
    FROM tpcds.promotion p
    WHERE p.p_promo_sk = cs.cs_promo_sk
      AND regexp_like(p.p_promo_name, '^Spring.*')
)
GROUP BY
    d.d_year,
    c.c_customer_id,
    i.i_brand,
    i.extracted_term,
    CONCAT(i.i_brand, '-', i.i_color)
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
