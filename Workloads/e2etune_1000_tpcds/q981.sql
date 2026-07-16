WITH store AS (
  SELECT
    r.r_reason_desc AS reason_desc,
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    sr.sr_net_loss AS net_loss,
    sr.sr_return_amt AS return_amt,
    'store' AS source
  FROM store_returns sr
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2450800 AND 2451100
),
web AS (
  SELECT
    r.r_reason_desc AS reason_desc,
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    wr.wr_net_loss AS net_loss,
    wr.wr_return_amt AS return_amt,
    'web' AS source
  FROM web_returns wr
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450800 AND 2451100
)
SELECT
  reason_desc,
  gender,
  marital_status,
  SUM(CASE WHEN source = 'store' THEN net_loss ELSE 0 END) AS store_net_loss,
  SUM(CASE WHEN source = 'web' THEN net_loss ELSE 0 END) AS web_net_loss,
  SUM(CASE WHEN source = 'store' THEN return_amt ELSE 0 END) AS store_return_amt,
  SUM(CASE WHEN source = 'web' THEN return_amt ELSE 0 END) AS web_return_amt,
  SUM(CASE WHEN source = 'store' THEN 1 ELSE 0 END) AS store_return_count,
  SUM(CASE WHEN source = 'web' THEN 1 ELSE 0 END) AS web_return_count,
  CASE WHEN SUM(CASE WHEN source = 'web' THEN net_loss ELSE 0 END) = 0 THEN NULL
       ELSE SUM(CASE WHEN source = 'store' THEN net_loss ELSE 0 END) /
            SUM(CASE WHEN source = 'web' THEN net_loss ELSE 0 END)
  END AS store_to_web_net_loss_ratio
FROM (
  SELECT * FROM store
  UNION ALL
  SELECT * FROM web
) combined
GROUP BY
  reason_desc,
  gender,
  marital_status
HAVING
  SUM(CASE WHEN source = 'store' THEN net_loss ELSE 0 END) > 0
ORDER BY
  store_net_loss DESC
LIMIT 100
