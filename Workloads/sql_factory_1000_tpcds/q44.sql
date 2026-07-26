WITH cr_daily AS (
  SELECT
    cr.cr_returned_date_sk AS date_sk,
    r.r_reason_desc AS reason_desc,
    SUM(cr.cr_net_loss) AS daily_catalog_loss
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  GROUP BY cr.cr_returned_date_sk, r.r_reason_desc
),
wr_daily AS (
  SELECT
    wr.wr_returned_date_sk AS date_sk,
    r.r_reason_desc AS reason_desc,
    SUM(wr.wr_net_loss) AS daily_web_loss
  FROM web_returns wr
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  GROUP BY wr.wr_returned_date_sk, r.r_reason_desc
),
combined_daily AS (
  SELECT
    COALESCE(cr.date_sk, wr.date_sk) AS date_sk,
    COALESCE(cr.reason_desc, wr.reason_desc) AS reason_desc,
    COALESCE(cr.daily_catalog_loss, 0) AS catalog_loss,
    COALESCE(wr.daily_web_loss, 0) AS web_loss,
    (COALESCE(cr.daily_catalog_loss, 0) + COALESCE(wr.daily_web_loss, 0)) AS total_loss
  FROM cr_daily cr
  FULL OUTER JOIN wr_daily wr ON cr.date_sk = wr.date_sk AND cr.reason_desc = wr.reason_desc
)
SELECT
  date_sk,
  reason_desc,
  catalog_loss,
  web_loss,
  total_loss,
  SUM(total_loss) OVER (PARTITION BY reason_desc ORDER BY date_sk ROWS UNBOUNDED PRECEDING) AS cumulative_loss,
  MIN(total_loss) OVER (PARTITION BY reason_desc) AS min_loss,
  MAX(total_loss) OVER (PARTITION BY reason_desc) AS max_loss,
  CASE WHEN total_loss = MAX(total_loss) OVER (PARTITION BY reason_desc) THEN 'MaxDay' ELSE '' END AS max_day_flag,
  RANK() OVER (PARTITION BY reason_desc ORDER BY total_loss ASC) AS asc_loss_rank
FROM combined_daily
WHERE total_loss IS NOT NULL
ORDER BY reason_desc, date_sk
