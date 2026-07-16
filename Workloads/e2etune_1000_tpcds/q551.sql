WITH state_returns AS (
  SELECT
    ca_ret.ca_state AS returning_state,
    ca_ref.ca_state AS refunded_state,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_store_credit) AS avg_store_credit,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(cr.cr_return_tax) / NULLIF(SUM(cr.cr_return_amount), 0) AS tax_to_return_ratio
  FROM catalog_returns cr
  JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
  JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  WHERE cr.cr_store_credit > 50
    AND cr.cr_returned_date_sk BETWEEN 2450900 AND 2451000
  GROUP BY ca_ret.ca_state, ca_ref.ca_state
  HAVING COUNT(*) >= 5
)
SELECT
  returning_state,
  refunded_state,
  num_returns,
  total_return_amount,
  total_net_loss,
  avg_store_credit,
  avg_return_tax,
  tax_to_return_ratio,
  RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM state_returns
ORDER BY total_net_loss DESC
LIMIT 20
