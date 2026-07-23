WITH base AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    cc.cc_name AS call_center_name,
    r.r_reason_desc,
    cr.cr_return_amount,
    ss.ss_net_profit,
    ss.ss_quantity,
    c.c_birth_month,
    td.t_hour
  FROM tpcds.catalog_returns cr
  INNER JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  INNER JOIN tpcds.reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  INNER JOIN tpcds.customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  INNER JOIN tpcds.customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  INNER JOIN tpcds.time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
  INNER JOIN tpcds.store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
  INNER JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
  WHERE cc.cc_name = 'Mid Atlantic'
    AND c.c_birth_month = 9
    AND td.t_hour BETWEEN 9 AND 17
    AND ss.ss_quantity > 0
),
agg AS (
  SELECT
    s_store_id,
    s_store_name,
    call_center_name,
    r_reason_desc,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ss_net_profit) AS total_net_profit,
    COUNT(*) AS return_count
  FROM base
  GROUP BY
    s_store_id,
    s_store_name,
    call_center_name,
    r_reason_desc
  HAVING SUM(cr_return_amount) > 1000
)
SELECT
  s_store_id,
  s_store_name,
  call_center_name,
  AVG(total_return_amount) AS avg_return_amount_per_reason,
  SUM(total_net_profit) AS total_net_profit_across_reasons,
  COUNT(*) AS reason_count
FROM agg
GROUP BY
  s_store_id,
  s_store_name,
  call_center_name
ORDER BY avg_return_amount_per_reason DESC
LIMIT 100
