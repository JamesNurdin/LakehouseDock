WITH store_loss AS (
  SELECT d.d_year AS year,
         r.r_reason_desc AS reason,
         SUM(sr.sr_net_loss) AS net_loss,
         'Store' AS source
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE d.d_year BETWEEN 1998 AND 1999
  GROUP BY d.d_year, r.r_reason_desc
),
web_loss AS (
  SELECT d.d_year AS year,
         r.r_reason_desc AS reason,
         SUM(wr.wr_net_loss) AS net_loss,
         'Web' AS source
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE d.d_year BETWEEN 1998 AND 1999
  GROUP BY d.d_year, r.r_reason_desc
),
catalog_loss AS (
  SELECT d.d_year AS year,
         r.r_reason_desc AS reason,
         SUM(cr.cr_net_loss) AS net_loss,
         'Catalog' AS source
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE d.d_year BETWEEN 1998 AND 1999
  GROUP BY d.d_year, r.r_reason_desc
)
SELECT year,
       reason,
       net_loss,
       source
FROM (
  SELECT year, reason, net_loss, source FROM store_loss
  UNION ALL
  SELECT year, reason, net_loss, source FROM web_loss
  UNION ALL
  SELECT year, reason, net_loss, source FROM catalog_loss
) combined
ORDER BY year DESC,
         net_loss DESC
LIMIT 100
