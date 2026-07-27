WITH joined AS (
  SELECT DISTINCT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_net_loss,
    sr.sr_ticket_number,
    sr.sr_net_loss,
    wr.wr_order_number,
    wr.wr_net_loss,
    d.d_year,
    r.r_reason_desc,
    CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS cr_amount_category,
    (cr.cr_net_loss + sr.sr_net_loss + wr.wr_net_loss) AS total_net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                      AND sr.sr_reason_sk = r.r_reason_sk
  JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                     AND wr.wr_reason_sk = r.r_reason_sk
  WHERE d.d_year IN (2001, 2002)
    AND r.r_reason_desc LIKE '%Not%'
    AND cr.cr_return_quantity > 0
    AND sr.sr_return_quantity > 0
    AND wr.wr_return_quantity > 0
    AND cr.cr_return_amount IS NOT NULL
)
SELECT
  d_year,
  r_reason_desc,
  cr_amount_category,
  COUNT(DISTINCT cr_order_number) AS catalog_orders,
  SUM(total_net_loss) AS total_net_loss,
  RANK() OVER (PARTITION BY d_year ORDER BY SUM(total_net_loss) DESC) AS loss_rank
FROM joined
GROUP BY d_year, r_reason_desc, cr_amount_category
HAVING SUM(total_net_loss) > 0
ORDER BY d_year, loss_rank
