WITH combined_returns AS (
   SELECT 'store' AS return_channel,
          d.d_year AS year,
          SUM(sr.sr_net_loss) AS total_net_loss,
          AVG(sr.sr_return_quantity) AS avg_return_quantity,
          SUM(sr.sr_return_amt) AS total_return_amount
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_date >= DATE '2000-01-01' AND d.d_date <= DATE '2002-12-31'
   GROUP BY d.d_year
   UNION ALL
   SELECT 'catalog' AS return_channel,
          d.d_year AS year,
          SUM(cr.cr_net_loss) AS total_net_loss,
          AVG(cr.cr_return_quantity) AS avg_return_quantity,
          SUM(cr.cr_return_amount) AS total_return_amount
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_date >= DATE '2000-01-01' AND d.d_date <= DATE '2002-12-31'
   GROUP BY d.d_year
   UNION ALL
   SELECT 'web' AS return_channel,
          d.d_year AS year,
          SUM(wr.wr_net_loss) AS total_net_loss,
          AVG(wr.wr_return_quantity) AS avg_return_quantity,
          SUM(wr.wr_return_amt) AS total_return_amount
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_date >= DATE '2000-01-01' AND d.d_date <= DATE '2002-12-31'
   GROUP BY d.d_year
)
SELECT return_channel,
       year,
       total_net_loss,
       avg_return_quantity,
       total_return_amount
FROM combined_returns
ORDER BY return_channel, year
