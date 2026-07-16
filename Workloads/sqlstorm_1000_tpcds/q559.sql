WITH returns AS (
  SELECT cr_returned_date_sk AS date_sk, cr_net_loss AS net_loss, cr_refunded_addr_sk AS addr_sk, 'catalog' AS source
  FROM catalog_returns
  UNION ALL
  SELECT sr_returned_date_sk AS date_sk, sr_net_loss AS net_loss, sr_addr_sk AS addr_sk, 'store' AS source
  FROM store_returns
  UNION ALL
  SELECT wr_returned_date_sk AS date_sk, wr_net_loss AS net_loss, wr_refunded_addr_sk AS addr_sk, 'web' AS source
  FROM web_returns
)
SELECT d.d_year,
       ca.ca_state,
       r.source,
       SUM(r.net_loss) AS total_net_loss,
       COUNT(*) AS return_count
FROM returns r
JOIN date_dim d ON r.date_sk = d.d_date_sk
JOIN customer_address ca ON r.addr_sk = ca.ca_address_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, ca.ca_state, r.source
ORDER BY total_net_loss DESC
LIMIT 100
