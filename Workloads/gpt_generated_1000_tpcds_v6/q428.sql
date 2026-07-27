WITH sales_returns AS (
  SELECT
    c.c_customer_id,
    cc.cc_name,
    sm.sm_type,
    r.r_reason_desc,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    cr.cr_return_amount,
    cr.cr_net_loss
  FROM store_sales ss
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
   AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cc.cc_state = 'CA'
    AND sm.sm_code = 'AIR'
    AND r.r_reason_desc LIKE '%damaged%'
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
),
aggregated AS (
  SELECT
    cc_name,
    sm_type,
    r_reason_desc,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(*) AS transaction_count
  FROM sales_returns
  GROUP BY ROLLUP (cc_name, sm_type, r_reason_desc)
)
SELECT
  cc_name,
  sm_type,
  r_reason_desc,
  total_sales,
  total_profit,
  total_return_amount,
  total_net_loss,
  transaction_count,
  total_profit / transaction_count AS avg_profit_per_txn
FROM aggregated
WHERE (total_profit / transaction_count) > (SELECT AVG(ss_net_profit) FROM store_sales)
ORDER BY avg_profit_per_txn DESC
LIMIT 100
