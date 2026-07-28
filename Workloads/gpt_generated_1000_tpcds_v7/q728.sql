WITH joined AS (
  SELECT
    cr.cr_order_number,
    cr.cr_item_sk,
    cr.cr_return_amount,
    cr.cr_net_loss AS cr_net_loss,
    cs.cs_net_paid_inc_tax,
    cs.cs_ext_list_price,
    cs.cs_coupon_amt,
    rs.r_reason_desc,
    t_cr.t_hour AS return_hour,
    wr.wr_net_loss,
    wr.wr_refunded_cash
  FROM catalog_returns cr
  JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
  JOIN reason rs
    ON cr.cr_reason_sk = rs.r_reason_sk
  JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
  JOIN web_returns wr
    ON wr.wr_reason_sk = rs.r_reason_sk
  JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
  WHERE cr.cr_refunded_cdemo_sk IN (519430, 1286874)
    AND wr.wr_refunded_cash > 100
    AND cs.cs_coupon_amt > 1000
    AND cs.cs_ext_list_price > 2000
    AND t_cr.t_hour BETWEEN 9 AND 17
),
aggregated AS (
  SELECT
    r_reason_desc,
    return_hour,
    SUM(cr_net_loss) AS total_catalog_return_loss,
    SUM(wr_net_loss) AS total_web_return_loss,
    COUNT(*) AS total_transactions,
    SUM(cr_net_loss + wr_net_loss) AS total_combined_loss
  FROM joined
  GROUP BY r_reason_desc, return_hour
  HAVING SUM(cr_net_loss + wr_net_loss) > 0
)
SELECT
  r_reason_desc,
  return_hour,
  total_catalog_return_loss,
  total_web_return_loss,
  total_transactions,
  total_combined_loss,
  RANK() OVER (ORDER BY total_combined_loss DESC) AS loss_rank
FROM aggregated
ORDER BY loss_rank
LIMIT 100
