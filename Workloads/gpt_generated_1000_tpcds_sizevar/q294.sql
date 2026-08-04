WITH
  sales AS (
    SELECT
      i.i_category AS category,
      'catalog_sales' AS src,
      SUM(cs.cs_ext_sales_price) AS total_amount
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND cs.cs_ext_sales_price > (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk BETWEEN 2451010 AND 2451020
      )
    GROUP BY i.i_category
  ),
  returns AS (
    SELECT
      i.i_category AS category,
      'catalog_returns' AS src,
      -SUM(cr.cr_return_amount) AS total_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
        SELECT 1
        FROM item i2
        WHERE i2.i_category = i.i_category
          AND i2.i_current_price > 1000
      )
    GROUP BY i.i_category
  )
SELECT
  category,
  src,
  SUM(total_amount) AS agg_amount
FROM (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM returns
) u
GROUP BY ROLLUP (category, src)
ORDER BY category NULLS LAST, src
LIMIT 100
