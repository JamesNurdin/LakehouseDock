WITH filtered_dates AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq
    FROM   tpcds.date_dim
    WHERE  d_year IN (1998, 1999, 2000)
)
SELECT   'return' AS metric_type,
         fd.d_year,
         SUM(cr.cr_return_amount) AS total_amount
FROM     tpcds.catalog_returns cr
JOIN     filtered_dates fd
       ON cr.cr_returned_date_sk = fd.d_date_sk
WHERE    cr.cr_return_quantity > 0
  AND    EXISTS (
            SELECT 1
            FROM   tpcds.web_sales ws
            WHERE  ws.ws_sold_date_sk = fd.d_date_sk
              AND  ws.ws_quantity > 0
         )
GROUP BY fd.d_year

UNION ALL

SELECT   'sale' AS metric_type,
         fd.d_year,
         SUM(ws.ws_ext_sales_price) AS total_amount
FROM     tpcds.web_sales ws
JOIN     filtered_dates fd
       ON ws.ws_sold_date_sk = fd.d_date_sk
WHERE    ws.ws_ext_discount_amt < (
            SELECT AVG(cr2.cr_return_amount)
            FROM   tpcds.catalog_returns cr2
            WHERE  cr2.cr_returned_date_sk = fd.d_date_sk
         )
GROUP BY fd.d_year

ORDER BY d_year,
         metric_type
LIMIT 100
