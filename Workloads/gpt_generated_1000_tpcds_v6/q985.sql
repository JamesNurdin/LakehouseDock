WITH store_agg AS (
  SELECT
    r.r_reason_desc AS reason_desc,
    td.t_hour AS hour,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
  FROM store_returns sr
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE td.t_hour BETWEEN 8 AND 20
    AND r.r_reason_id = 'R001'
  GROUP BY r.r_reason_desc, td.t_hour
  HAVING SUM(sr.sr_net_loss) > 1000
),

catalog_agg AS (
  SELECT
    r.r_reason_desc AS reason_desc,
    td.t_hour AS hour,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE td.t_hour BETWEEN 8 AND 20
    AND r.r_reason_id = 'R001'
  GROUP BY r.r_reason_desc, td.t_hour
  HAVING SUM(cr.cr_net_loss) > 1000
),

unioned AS (
  SELECT reason_desc, hour, total_net_loss, return_count FROM store_agg
  UNION ALL
  SELECT reason_desc, hour, total_net_loss, return_count FROM catalog_agg
)

SELECT
  reason_desc,
  hour,
  total_net_loss,
  return_count,
  ROW_NUMBER() OVER (PARTITION BY reason_desc ORDER BY total_net_loss DESC) AS loss_rank
FROM unioned
ORDER BY total_net_loss DESC
LIMIT 100
