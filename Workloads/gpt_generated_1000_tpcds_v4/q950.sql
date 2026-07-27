WITH union_returns AS (
  SELECT
    cr.cr_returned_date_sk AS return_date_sk,
    cr.cr_returned_time_sk AS time_sk,
    cr.cr_return_amount AS return_amount,
    cr.cr_reason_sk AS reason_sk,
    cr.cr_warehouse_sk AS warehouse_sk,
    cr.cr_catalog_page_sk AS catalog_page_sk,
    cr.cr_refunded_customer_sk AS customer_sk,
    cr.cr_refunded_addr_sk AS address_sk,
    cr.cr_refunded_cdemo_sk AS cdemo_sk,
    cr.cr_refunded_hdemo_sk AS hdemo_sk,
    cr.cr_return_quantity AS quantity,
    'catalog' AS source
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE td.t_hour BETWEEN 9 AND 17
    AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'
    AND c.c_preferred_cust_flag = 'Y'
    AND w.w_state = 'TX'
    AND cp.cp_department = 'Electronics'
),
store_union AS (
  SELECT
    sr.sr_returned_date_sk AS return_date_sk,
    sr.sr_return_time_sk AS time_sk,
    sr.sr_return_amt AS return_amount,
    sr.sr_reason_sk AS reason_sk,
    sr.sr_store_sk AS store_sk,
    sr.sr_customer_sk AS customer_sk,
    sr.sr_addr_sk AS address_sk,
    sr.sr_cdemo_sk AS cdemo_sk,
    sr.sr_hdemo_sk AS hdemo_sk,
    sr.sr_return_quantity AS quantity,
    'store' AS source
  FROM store_returns sr
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
  WHERE td.t_hour BETWEEN 9 AND 17
    AND r.r_reason_desc LIKE 'Did not %'
    AND s.s_county = 'Dauphin County'
    AND c.c_birth_year > 1980
    AND wp.wp_type = 'Home'
)
SELECT
  final.reason_desc,
  COUNT(DISTINCT final.customer_sk) AS distinct_customers,
  SUM(final.return_amount) AS total_return_amount,
  AVG(final.quantity) AS avg_quantity
FROM (
  SELECT
    u.return_amount,
    u.quantity,
    u.customer_sk,
    r.r_reason_desc AS reason_desc
  FROM union_returns u
  JOIN reason r ON u.reason_sk = r.r_reason_sk
  UNION ALL
  SELECT
    s.return_amount,
    s.quantity,
    s.customer_sk,
    r.r_reason_desc AS reason_desc
  FROM store_union s
  JOIN reason r ON s.reason_sk = r.r_reason_sk
) final
GROUP BY final.reason_desc
HAVING SUM(final.return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
