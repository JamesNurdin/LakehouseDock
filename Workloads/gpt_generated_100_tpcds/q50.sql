WITH agg AS (
  SELECT
    ca_refunded.ca_state AS refunded_state,
    ca_returning.ca_state AS returning_state,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity
  FROM catalog_returns cr
  JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
  JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
  GROUP BY ca_refunded.ca_state, ca_returning.ca_state
)
SELECT
  refunded_state,
  returning_state,
  num_returns,
  total_return_amount,
  total_net_loss,
  avg_return_quantity,
  RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
  total_net_loss / SUM(total_net_loss) OVER () * 100 AS net_loss_pct
FROM agg
ORDER BY net_loss_rank
LIMIT 20
