WITH sales_agg AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_bill_customer_sk,
    cs.cs_call_center_sk,
    cs.cs_catalog_page_sk,
    cs.cs_ship_mode_sk,
    cs.cs_promo_sk,
    cs.cs_order_number,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion pr ON cs.cs_promo_sk = pr.p_promo_sk
  WHERE cu.c_last_name = 'Moore'
    AND cu.c_birth_month = 9
    AND cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND pr.p_discount_active = 'Y'
    AND cp.cp_type = 'PROMO'
  GROUP BY
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_bill_customer_sk,
    cs.cs_call_center_sk,
    cs.cs_catalog_page_sk,
    cs.cs_ship_mode_sk,
    cs.cs_promo_sk,
    cs.cs_order_number
),
returns_agg AS (
  SELECT
    cr.cr_order_number,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN customer cu ON cr.cr_refunded_customer_sk = cu.c_customer_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cr.cr_return_ship_cost > 1000
    AND cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND cp.cp_type = 'PROMO'
    AND cu.c_last_name = 'Moore'
    AND cu.c_birth_month = 9
  GROUP BY cr.cr_order_number
),
web_returns_agg AS (
  SELECT
    wr.wr_order_number,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    COUNT(DISTINCT wr.wr_returning_addr_sk) AS distinct_returning_addr_cnt
  FROM web_returns wr
  JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
  JOIN customer cu ON wr.wr_refunded_customer_sk = cu.c_customer_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE wr.wr_return_ship_cost > 500
    AND cu.c_last_name = 'Moore'
    AND cu.c_birth_month = 9
    AND ca.ca_state = 'CA'
  GROUP BY wr.wr_order_number
)
SELECT
  s.cs_sold_date_sk,
  s.cs_bill_customer_sk,
  c.c_customer_id,
  cc.cc_name,
  cp.cp_description,
  sm.sm_carrier,
  pr.p_promo_name,
  s.total_net_paid,
  r.total_return_amount,
  w.total_web_return_amt,
  s.sales_cnt,
  r.return_cnt,
  w.distinct_returning_addr_cnt,
  RANK() OVER (ORDER BY s.total_net_paid DESC) AS revenue_rank,
  SUM(s.total_net_paid) OVER (PARTITION BY s.cs_bill_customer_sk ORDER BY s.cs_sold_date_sk
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_customer_paid
FROM sales_agg s
LEFT JOIN returns_agg r ON s.cs_order_number = r.cr_order_number
LEFT JOIN web_returns_agg w ON s.cs_order_number = w.wr_order_number
JOIN customer c ON s.cs_bill_customer_sk = c.c_customer_sk
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion pr ON s.cs_promo_sk = pr.p_promo_sk
WHERE s.total_net_paid > 0
ORDER BY revenue_rank
LIMIT 100
