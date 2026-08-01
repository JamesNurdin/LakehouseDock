WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
)
SELECT d_date
FROM (
    SELECT d.d_date
    FROM sampled_inventory inv
    RIGHT JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND inv.inv_quantity_on_hand > 500
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_returned_date_sk = d.d_date_sk
      )
) 
EXCEPT
SELECT d_date
FROM (
    SELECT d.d_date
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
LIMIT 100
