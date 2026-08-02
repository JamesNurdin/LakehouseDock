WITH catalog_blue_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)blue')
      AND i.i_category LIKE 'Electronics%'
),
store_blue_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_item_desc LIKE '%Blue%'
      AND regexp_like(i.i_item_desc, '(?i)blue')
),
blue_customers AS (
    SELECT c_customer_sk FROM catalog_blue_customers
    INTERSECT
    SELECT c_customer_sk FROM store_blue_customers
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_item_id,
    i.i_product_name,
    regexp_extract(i.i_item_desc, '([A-Za-z]+)', 1) AS first_word_in_desc,
    concat(i.i_brand, '-', i.i_category) AS brand_category,
    cs.cs_net_paid AS catalog_net_paid,
    ss.ss_net_paid AS store_net_paid,
    cr_lateral.cr_return_amount,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.cs_sold_date_sk DESC) AS purchase_rank
FROM blue_customers bc
JOIN customer c ON bc.c_customer_sk = c.c_customer_sk
JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
CROSS JOIN LATERAL (
    SELECT cr.cr_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = cs.cs_item_sk
      AND cr.cr_order_number = cs.cs_order_number
    ORDER BY cr.cr_returned_date_sk DESC
    LIMIT 1
) AS cr_lateral
JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    AND ss.ss_item_sk = i.i_item_sk
WHERE i.i_item_desc LIKE '%Blue%'
  AND regexp_like(i.i_item_desc, '(?i)Blue')
ORDER BY cs.cs_net_paid DESC
LIMIT 100
