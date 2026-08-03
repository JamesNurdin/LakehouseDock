/* goal: Identify catalog return order numbers in the year 2000 for stores that were not closed on the return date, and exclude any of those orders that also appear as web returns in the same year. */
WITH catalog_orders AS (
    SELECT DISTINCT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND s.s_store_sk IS NULL
),
web_orders AS (
    SELECT DISTINCT wr.wr_order_number AS order_number
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND wr.wr_return_amt_inc_tax > 0
)
SELECT order_number
FROM catalog_orders
EXCEPT
SELECT order_number
FROM web_orders
LIMIT 100
