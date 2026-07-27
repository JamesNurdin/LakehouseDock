WITH agg_returns AS (
    SELECT d.d_date AS return_date,
           SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
           CAST('store' AS VARCHAR) AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_return_amt_inc_tax > 100
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_date
    UNION ALL
    SELECT d.d_date AS return_date,
           SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
           CAST('web' AS VARCHAR) AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE wr.wr_return_amt_inc_tax > 100
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_date
)
SELECT return_date,
       total_return_amount,
       source
FROM agg_returns
ORDER BY return_date DESC,
         total_return_amount DESC
LIMIT 100
