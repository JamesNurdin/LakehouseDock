WITH sales_agg AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_category,
           SUM(cs.cs_quantity) AS total_qty,
           SUM(cs.cs_net_paid) AS total_amount,
           (
               SELECT AVG(i2.i_current_price)
               FROM item i2
               WHERE i2.i_category = i.i_category
           ) AS avg_category_price
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, i.i_product_name, i.i_category
)

SELECT s.i_item_sk,
       s.i_product_name,
       s.total_qty,
       s.total_amount,
       s.avg_category_price,
       'sale' AS activity_type
FROM sales_agg s
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    WHERE cr.cr_item_sk = s.i_item_sk
      AND d2.d_year = 2001
)

UNION ALL

SELECT r.i_item_sk,
       i.i_product_name,
       r.total_qty,
       r.total_amount,
       (
           SELECT AVG(i2.i_current_price)
           FROM item i2
           WHERE i2.i_category = i.i_category
       ) AS avg_category_price,
       'return' AS activity_type
FROM (
    SELECT cr.cr_item_sk AS i_item_sk,
           SUM(cr.cr_return_quantity) AS total_qty,
           SUM(cr.cr_return_amount) AS total_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cr.cr_item_sk
) r
JOIN item i ON r.i_item_sk = i.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs
    JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
    WHERE cs.cs_item_sk = r.i_item_sk
      AND d2.d_year = 2001
)

ORDER BY total_amount DESC, activity_type
LIMIT 100
