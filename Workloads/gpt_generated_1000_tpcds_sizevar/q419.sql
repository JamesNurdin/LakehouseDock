WITH
  full_join AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_return_amount,
      i.i_item_sk,
      i.i_brand,
      i.i_category,
      i.i_wholesale_cost
    FROM catalog_returns cr
    FULL OUTER JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 5 OR i.i_wholesale_cost < 3
  ),
  agg AS (
    SELECT
      i.i_item_sk,
      i.i_brand,
      i.i_category,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_refunded_cash) AS total_refunded_cash
    FROM catalog_returns cr
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 10
    GROUP BY GROUPING SETS (
      (i.i_item_sk, i.i_brand, i.i_category),
      (i.i_item_sk, i.i_brand),
      (i.i_item_sk, i.i_category),
      (i.i_item_sk)
    )
  )
SELECT
  a.i_brand,
  a.i_category,
  a.total_return_amount,
  a.total_refunded_cash
FROM agg a
WHERE a.i_item_sk IN (
        SELECT i_item_sk FROM agg
        INTERSECT
        SELECT cr_item_sk FROM catalog_returns WHERE cr_return_quantity > 1
      )
  AND EXISTS (
        SELECT 1 FROM full_join fj
        WHERE fj.cr_item_sk = a.i_item_sk
          AND fj.i_brand IS NOT NULL
      )
ORDER BY a.total_return_amount DESC
LIMIT 100
