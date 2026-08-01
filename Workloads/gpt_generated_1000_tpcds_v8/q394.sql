WITH common_cust AS (
  SELECT cr_refunded_customer_sk AS c_customer_sk
  FROM catalog_returns
  INTERSECT
  SELECT sr_customer_sk
  FROM store_returns
)

SELECT
  cust_ref.c_customer_id,
  hd_cur.hd_income_band_sk,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(sr.sr_return_amt) AS total_store_return_amount,
  ca.total_return_amount
FROM common_cust cc
JOIN customer cust_ref
  ON cc.c_customer_sk = cust_ref.c_customer_sk
JOIN customer cust_ret
  ON cc.c_customer_sk = cust_ret.c_customer_sk
JOIN store_returns sr
  ON sr.sr_customer_sk = cust_ref.c_customer_sk
JOIN catalog_returns cr
  ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
JOIN time_dim td_cat
  ON cr.cr_returned_time_sk = td_cat.t_time_sk
JOIN time_dim td_store
  ON sr.sr_return_time_sk = td_store.t_time_sk
JOIN household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
  ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_store
  ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
JOIN household_demographics hd_cur
  ON cust_ref.c_current_hdemo_sk = hd_cur.hd_demo_sk
JOIN income_band ib
  ON hd_cur.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN LATERAL (
  SELECT SUM(cr2.cr_return_amount) AS total_return_amount
  FROM catalog_returns cr2
  WHERE cr2.cr_returning_customer_sk = cust_ref.c_customer_sk
) ca ON true
WHERE EXISTS (
  SELECT 1
  FROM store_returns sr2
  WHERE sr2.sr_customer_sk = cust_ref.c_customer_sk
    AND sr2.sr_return_tax > 5
)
GROUP BY
  cust_ref.c_customer_id,
  hd_cur.hd_income_band_sk,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  ca.total_return_amount
ORDER BY total_store_return_amount DESC
LIMIT 100
