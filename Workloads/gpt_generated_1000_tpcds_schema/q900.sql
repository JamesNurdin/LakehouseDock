WITH joined AS (
  SELECT
    sr.sr_addr_sk,
    ca.ca_state,
    ca.ca_city,
    ca.ca_zip,
    sr.sr_customer_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_return_tax,
    sr.sr_refunded_cash,
    sr.sr_store_credit,
    sr.sr_net_loss,
    ARRAY[sr.sr_return_quantity, CAST(sr.sr_return_amt AS double), CAST(sr.sr_return_tax AS double)] AS measures_arr
  FROM store_returns sr
  JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE ca.ca_state = 'CA'
    AND ca.ca_city = 'Jackson'
    AND sr.sr_return_amt > 10
),
aggregated AS (
  SELECT
    j.ca_state,
    j.ca_city,
    j.ca_zip,
    j.sr_customer_sk,
    SUM(j.sr_return_amt) AS total_return_amt,
    AVG(j.sr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MIN(j.sr_return_quantity) AS min_quantity,
    MAX(j.sr_return_quantity) AS max_quantity,
    CASE
      WHEN SUM(j.sr_return_amt) > 1000 THEN 'HIGH'
      WHEN SUM(j.sr_return_amt) > 500 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS return_level,
    (SELECT SUM(sr2.sr_return_amt)
     FROM store_returns sr2
     WHERE sr2.sr_customer_sk = j.sr_customer_sk) AS customer_total_return_amt
  FROM joined j
  GROUP BY CUBE (j.ca_state, j.ca_city), j.ca_zip, j.sr_customer_sk
),
key_diff AS (
  SELECT sr.sr_customer_sk
  FROM store_returns sr
  EXCEPT
  SELECT ca.ca_address_sk
  FROM customer_address ca
),
ranked AS (
  SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY a.ca_state ORDER BY a.total_return_amt DESC) AS rn,
    metric_val
  FROM aggregated a
  CROSS JOIN UNNEST(ARRAY[a.min_quantity, a.max_quantity, a.return_cnt]) AS t(metric_val)
  WHERE a.sr_customer_sk IN (SELECT sr_customer_sk FROM key_diff)
)
SELECT
  rn,
  ca_state,
  ca_city,
  ca_zip,
  total_return_amt,
  avg_return_tax,
  return_cnt,
  min_quantity,
  max_quantity,
  return_level,
  customer_total_return_amt,
  metric_val
FROM ranked
WHERE rn <= 5
LIMIT 100
