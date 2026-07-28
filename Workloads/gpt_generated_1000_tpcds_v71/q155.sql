/*
Goal: Identify top‑earning catalog departments and item brands, excluding orders that had any large return (> $500) while applying multiple realistic filters.
*/
WITH sales_page AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        cs.cs_net_paid_inc_tax,
        cs.cs_quantity,
        cp.cp_department,
        cp.cp_catalog_page_number,
        cp.cp_end_date_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_net_paid_inc_tax > 1000                                   -- filter 1
      AND cs.cs_quantity BETWEEN 1 AND 5                                 -- filter 2
      AND cp.cp_catalog_page_number IN (8, 15)                           -- filter 3
      AND cp.cp_end_date_sk > 2450900                                    -- filter 4
)
SELECT
    sp.cp_department,
    i.i_brand,
    COUNT(DISTINCT sp.cs_order_number)               AS order_cnt,
    SUM(sp.cs_net_paid_inc_tax)                       AS total_net_paid,
    AVG(sp.cs_net_paid_inc_tax)                       AS avg_net_paid,
    MIN(sp.cs_net_paid_inc_tax)                       AS min_net_paid,
    MAX(sp.cs_net_paid_inc_tax)                       AS max_net_paid,
    SUM(cr.cr_return_amount)                          AS total_return_amount
FROM sales_page sp
JOIN catalog_returns cr
    ON cr.cr_order_number = sp.cs_order_number
   AND cr.cr_item_sk       = sp.cs_item_sk
   AND cr.cr_catalog_page_sk = sp.cs_catalog_page_sk
JOIN item i
    ON i.i_item_sk = sp.cs_item_sk
WHERE i.i_rec_end_date > DATE '2000-01-01'                                 -- filter 5
  AND i.i_product_name LIKE '%able%'                                        -- filter 6
  AND cr.cr_return_quantity = 0                                            -- filter 7
  AND NOT EXISTS (                                                          -- anti‑join (exclude orders with large returns)
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = sp.cs_order_number
          AND cr2.cr_return_amount > 500
    )
GROUP BY sp.cp_department, i.i_brand
ORDER BY total_net_paid DESC
LIMIT 100
