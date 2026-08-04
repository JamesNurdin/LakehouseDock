WITH cat_ids AS (
    SELECT DISTINCT cr.cr_order_number AS order_id,
           CASE WHEN cr.cr_return_amount > 2000 THEN 'HIGH' ELSE 'MEDIUM' END AS return_level
    FROM (SELECT * FROM catalog_returns TABLESAMPLE BERNOULLI (10)) cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 1000
),
store_ids AS (
    SELECT DISTINCT sr.sr_ticket_number AS order_id,
           CASE WHEN sr.sr_return_amt > 2000 THEN 'HIGH' ELSE 'MEDIUM' END AS return_level
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sr.sr_return_amt > 1000
)
SELECT t.order_id,
       t.return_level
FROM (
    SELECT order_id, return_level FROM cat_ids
    INTERSECT
    SELECT order_id, return_level FROM store_ids
) t
ORDER BY t.order_id
LIMIT 100
