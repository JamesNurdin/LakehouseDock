WITH
  sales_data AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      ss.ss_sold_date_sk            AS trans_date_sk,
      ss.ss_ticket_number           AS ticket_number,
      ss.ss_ext_sales_price,
      ss.ss_ext_tax,
      ARRAY[ss.ss_ext_sales_price, ss.ss_ext_tax] AS metrics,
      CASE WHEN ss.ss_coupon_amt > 0 THEN 'Coupon' ELSE 'No Coupon' END AS coupon_flag,
      CAST(NULL AS varchar)        AS fee_flag,
      'sale'                        AS transaction_type
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
  ),
  returns_data AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      sr.sr_returned_date_sk       AS trans_date_sk,
      sr.sr_ticket_number          AS ticket_number,
      sr.sr_return_amt,
      sr.sr_return_tax,
      ARRAY[sr.sr_return_amt, sr.sr_return_tax] AS metrics,
      CAST(NULL AS varchar)        AS coupon_flag,
      CASE WHEN sr.sr_fee > 0 THEN 'Fee' ELSE 'No Fee' END AS fee_flag,
      'return'                     AS transaction_type
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
  ),
  combined AS (
    SELECT
      s_store_id,
      s_store_name,
      trans_date_sk,
      ticket_number,
      metrics,
      coupon_flag,
      fee_flag,
      transaction_type
    FROM sales_data
    UNION ALL
    SELECT
      s_store_id,
      s_store_name,
      trans_date_sk,
      ticket_number,
      metrics,
      coupon_flag,
      fee_flag,
      transaction_type
    FROM returns_data
  )
SELECT
  c.s_store_id,
  c.s_store_name,
  c.trans_date_sk,
  c.ticket_number,
  metric_value,
  metric_idx,
  c.coupon_flag,
  c.fee_flag,
  c.transaction_type
FROM combined c
CROSS JOIN UNNEST(c.metrics) WITH ORDINALITY AS t(metric_value, metric_idx)
ORDER BY c.s_store_id, c.trans_date_sk DESC
LIMIT 100
