WITH
  store_ret AS (
    SELECT
      s.s_store_id               AS entity_id,
      d.d_month_seq,
      d.d_year,
      sr.sr_customer_sk          AS customer_sk,
      sr.sr_return_amt_inc_tax   AS return_inc_tax,
      sr.sr_fee                  AS fee
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
  ),
  catalog_ret AS (
    SELECT
      cc.cc_call_center_id      AS entity_id,
      d.d_month_seq,
      d.d_year,
      cr.cr_refunded_customer_sk AS customer_sk,
      cr.cr_return_amt_inc_tax   AS return_inc_tax,
      cr.cr_fee                  AS fee
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
  ),
  union_all AS (
    SELECT * FROM store_ret
    UNION
    SELECT * FROM catalog_ret
  )
SELECT
  entity_id,
  d_year,
  d_month_seq,
  COUNT(DISTINCT customer_sk)                 AS distinct_customers,
  SUM(DISTINCT return_inc_tax)                AS sum_distinct_return_inc_tax,
  SUM(DISTINCT fee)                           AS sum_distinct_fee,
  (SELECT MAX(d_date) FROM date_dim WHERE d_year = union_all.d_year) AS max_date_of_year
FROM union_all
GROUP BY CUBE (entity_id, d_year, d_month_seq)
ORDER BY entity_id, d_year DESC, d_month_seq
OFFSET 0 LIMIT 100
