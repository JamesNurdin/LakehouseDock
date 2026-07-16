WITH store_ret AS (
  SELECT
    r.r_reason_desc AS reason,
    ca.ca_state AS state,
    sr.sr_net_loss AS net_loss,
    sr.sr_returned_date_sk AS return_date_sk
  FROM store_returns sr
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2450997
),
catalog_ret AS (
  SELECT
    r.r_reason_desc AS reason,
    ca.ca_state AS state,
    cr.cr_net_loss AS net_loss,
    cr.cr_returned_date_sk AS return_date_sk
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2450997
),
web_ret AS (
  SELECT
    r.r_reason_desc AS reason,
    ca.ca_state AS state,
    wr.wr_net_loss AS net_loss,
    wr.wr_returned_date_sk AS return_date_sk
  FROM web_returns wr
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2450997
),
combined AS (
  SELECT reason, state, net_loss FROM store_ret
  UNION ALL
  SELECT reason, state, net_loss FROM catalog_ret
  UNION ALL
  SELECT reason, state, net_loss FROM web_ret
)
SELECT
  state,
  reason,
  SUM(net_loss) AS total_net_loss,
  RANK() OVER (PARTITION BY state ORDER BY SUM(net_loss) DESC) AS reason_rank
FROM combined
GROUP BY state, reason
HAVING SUM(net_loss) > 0
ORDER BY state, total_net_loss DESC
LIMIT 10
