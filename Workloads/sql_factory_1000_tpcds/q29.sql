WITH cr AS (
  SELECT
    cr.cr_reason_sk,
    SUM(cr.cr_net_loss) AS total_catalog_loss,
    COUNT(*) AS catalog_return_cnt
  FROM catalog_returns cr
  GROUP BY cr.cr_reason_sk
),
wr AS (
  SELECT
    wr.wr_reason_sk,
    SUM(wr.wr_net_loss) AS total_web_loss,
    COUNT(*) AS web_return_cnt
  FROM web_returns wr
  GROUP BY wr.wr_reason_sk
)
SELECT
  r.r_reason_desc,
  COALESCE(cr.total_catalog_loss, 0) AS catalog_loss,
  COALESCE(wr.total_web_loss, 0) AS web_loss,
  (COALESCE(cr.total_catalog_loss, 0) + COALESCE(wr.total_web_loss, 0)) AS total_loss,
  CASE
    WHEN (COALESCE(cr.total_catalog_loss, 0) + COALESCE(wr.total_web_loss, 0)) > 10000 THEN 'High'
    WHEN (COALESCE(cr.total_catalog_loss, 0) + COALESCE(wr.total_web_loss, 0)) BETWEEN 5000 AND 10000 THEN 'Medium'
    ELSE 'Low'
  END AS loss_category,
  RANK() OVER (ORDER BY (COALESCE(cr.total_catalog_loss, 0) + COALESCE(wr.total_web_loss, 0)) DESC) AS loss_rank
FROM reason r
LEFT JOIN cr ON r.r_reason_sk = cr.cr_reason_sk
LEFT JOIN wr ON r.r_reason_sk = wr.wr_reason_sk
ORDER BY total_loss DESC
LIMIT 20
