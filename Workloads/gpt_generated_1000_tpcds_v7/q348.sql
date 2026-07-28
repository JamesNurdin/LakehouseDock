WITH catalog_monthly AS (
   SELECT d.d_year AS year,
          d.d_moy AS month,
          SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
          'catalog' AS source
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE i.i_current_price > 5
   GROUP BY d.d_year, d.d_moy
),
web_monthly AS (
   SELECT d.d_year AS year,
          d.d_moy AS month,
          SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
          'web' AS source
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   WHERE i.i_current_price > 5
   GROUP BY d.d_year, d.d_moy
)
SELECT year,
       month,
       total_return_amount,
       source
FROM catalog_monthly
UNION ALL
SELECT year,
       month,
       total_return_amount,
       source
FROM web_monthly
ORDER BY year, month, source
