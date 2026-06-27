WITH unified_returns AS (
  SELECT
    i.i_category,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    r.r_reason_desc,
    'catalog' AS channel,
    cr.cr_return_amount AS return_amount,
    cr.cr_net_loss AS net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'

  UNION ALL

  SELECT
    i.i_category,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    r.r_reason_desc,
    'store' AS channel,
    sr.sr_return_amt AS return_amount,
    sr.sr_net_loss AS net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'

  UNION ALL

  SELECT
    i.i_category,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    r.r_reason_desc,
    'web' AS channel,
    wr.wr_return_amt AS return_amount,
    wr.wr_net_loss AS net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
),
aggregated AS (
  SELECT
    i_category,
    d_year,
    d_month_seq,
    cd_gender,
    r_reason_desc,
    channel,
    SUM(return_amount) AS total_return_amount,
    SUM(net_loss) AS total_net_loss,
    COUNT(*) AS return_count
  FROM unified_returns
  GROUP BY
    i_category,
    d_year,
    d_month_seq,
    cd_gender,
    r_reason_desc,
    channel
)
SELECT
  i_category,
  d_year,
  d_month_seq,
  cd_gender,
  r_reason_desc,
  channel,
  total_return_amount,
  total_net_loss,
  return_count,
  RANK() OVER (PARTITION BY i_category, d_year, d_month_seq ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
