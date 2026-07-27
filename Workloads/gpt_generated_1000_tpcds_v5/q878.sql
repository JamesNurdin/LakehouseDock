WITH joined AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_state,
    cc.cc_gmt_offset,
    w.w_warehouse_sk,
    w.w_state AS warehouse_state,
    ca.ca_state AS cust_state,
    c.c_customer_sk,
    c.c_birth_month,
    wp.wp_type,
    cr.cr_return_amount,
    cr.cr_net_loss,
    CASE WHEN cc.cc_gmt_offset >= 0 THEN 'East' ELSE 'West' END AS gmt_region,
    CASE WHEN c.c_birth_month IN (1, 2, 3) THEN 'Q1' ELSE 'Other' END AS birth_quarter
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
  WHERE cc.cc_class = 'large'
    AND cc.cc_state = 'CA'
    AND ca.ca_state = 'CA'
    AND w.w_state = 'CA'
    AND c.c_birth_month = 7
    AND wp.wp_type = 'product'
),
agg AS (
  SELECT
    cc_call_center_sk,
    cc_name,
    cc_state,
    gmt_region,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(cr_return_amount) AS avg_return_amount
  FROM joined
  GROUP BY
    cc_call_center_sk,
    cc_name,
    cc_state,
    gmt_region
)
SELECT
  cc_call_center_sk,
  cc_name,
  cc_state,
  gmt_region,
  total_return_amount,
  total_net_loss,
  return_cnt,
  avg_return_amount,
  RANK() OVER (PARTITION BY cc_state ORDER BY total_return_amount DESC) AS state_return_rank,
  SUM(total_return_amount) OVER (PARTITION BY gmt_region ORDER BY cc_name ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_by_region
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
