WITH cr_daily AS (
  SELECT
    cr.cr_returned_date_sk AS date_sk,
    r.r_reason_desc AS reason_desc,
    SUM(cr.cr_net_loss) AS daily_catalog_loss,
    COUNT(*) AS catalog_return_cnt
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cr.cr_returned_date_sk >= 20200101
  GROUP BY cr.cr_returned_date_sk, r.r_reason_desc
),
wr_daily AS (
  SELECT
    wr.wr_returned_date_sk AS date_sk,
    r.r_reason_desc AS reason_desc,
    SUM(wr.wr_net_loss) AS daily_web_loss,
    COUNT(*) AS web_return_cnt
  FROM web_returns wr
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE wr.wr_returned_date_sk >= 20200101
  GROUP BY wr.wr_returned_date_sk, r.r_reason_desc
),
combined_daily AS (
  SELECT
    COALESCE(cr.date_sk, wr.date_sk) AS date_sk,
    COALESCE(cr.reason_desc, wr.reason_desc) AS reason_desc,
    COALESCE(cr.daily_catalog_loss, 0) AS catalog_loss,
    COALESCE(wr.daily_web_loss, 0) AS web_loss,
    (COALESCE(cr.daily_catalog_loss, 0) + COALESCE(wr.daily_web_loss, 0)) AS total_loss,
    COALESCE(cr.catalog_return_cnt, 0) AS catalog_cnt,
    COALESCE(wr.web_return_cnt, 0) AS web_cnt
  FROM cr_daily cr
  FULL OUTER JOIN wr_daily wr ON cr.date_sk = wr.date_sk AND cr.reason_desc = wr.reason_desc
)
SELECT
  date_sk,
  reason_desc,
  catalog_loss,
  web_loss,
  total_loss,
  catalog_cnt,
  web_cnt,
  SUM(total_loss) OVER (PARTITION BY reason_desc ORDER BY date_sk) AS cumulative_loss,
  AVG(total_loss) OVER (PARTITION BY reason_desc) AS avg_daily_loss,
  CASE WHEN total_loss > 8000 THEN 'Critical' WHEN total_loss > 3000 THEN 'High' ELSE 'Low' END AS loss_severity,
  ROW_NUMBER() OVER (PARTITION BY reason_desc ORDER BY total_loss DESC) AS loss_rank
FROM combined_daily
ORDER BY reason_desc, date_sk
