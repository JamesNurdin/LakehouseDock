WITH agg AS (
  SELECT
    cr.cr_reason_sk,
    ws.web_state,
    SUM(cr.cr_return_quantity) AS total_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
  FROM catalog_returns cr
  JOIN web_site ws
    ON (cr.cr_return_quantity % 10) = (ws.web_site_sk % 10)
  WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451100
    AND cr.cr_return_quantity > 5
    AND cr.cr_reason_sk IN (16, 17, 59, 65)
  GROUP BY cr.cr_reason_sk, ws.web_state
  HAVING SUM(cr.cr_return_quantity) > 20
)
SELECT
  agg.cr_reason_sk,
  agg.web_state,
  agg.total_qty,
  agg.total_return_amount,
  agg.total_net_loss,
  agg.distinct_orders,
  RANK() OVER (PARTITION BY agg.web_state ORDER BY agg.total_net_loss DESC) AS state_net_loss_rank,
  (SELECT COUNT(*) FROM web_site) AS total_web_sites
FROM agg
ORDER BY agg.total_net_loss DESC
LIMIT 20
