WITH store_data AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE r.r_reason_desc LIKE '%damaged%'
    AND d.d_year = 2002
  GROUP BY d.d_year, i.i_category
),
catalog_data AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE r.r_reason_desc LIKE '%unauthoized purchase%'
    AND d.d_year = 2002
  GROUP BY d.d_year, i.i_category
)
SELECT *
FROM (
  SELECT 'store'   AS source, d_year, i_category, total_net_loss, return_cnt
  FROM store_data
  UNION ALL
  SELECT 'catalog' AS source, d_year, i_category, total_net_loss, return_cnt
  FROM catalog_data
) combined
WHERE total_net_loss > (
  SELECT AVG(cr.cr_net_loss)
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
)
ORDER BY total_net_loss DESC
LIMIT 100
