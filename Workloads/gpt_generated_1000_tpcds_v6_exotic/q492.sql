WITH combined AS (
    SELECT cr.cr_item_sk AS item_sk,
           cr.cr_returned_date_sk AS date_sk,
           d.d_year AS year,
           cr.cr_return_amount AS return_amount,
           'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_return_amount > 20.00
      AND d.d_year = 2001
    UNION ALL
    SELECT sr.sr_item_sk AS item_sk,
           sr.sr_returned_date_sk AS date_sk,
           d.d_year AS year,
           sr.sr_return_amt AS return_amount,
           'store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_return_amt > 20.00
      AND d.d_year = 2001
)
SELECT c.item_sk,
       c.date_sk,
       c.year,
       c.return_amount,
       c.source
FROM combined c
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory i
    WHERE i.inv_item_sk = c.item_sk
      AND i.inv_date_sk = c.date_sk
)
ORDER BY c.year DESC, c.return_amount DESC
LIMIT 100
