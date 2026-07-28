WITH sales_agg AS (
  SELECT
    cc.cc_name,
    sm.sm_type,
    td.t_hour,
    ca.ca_state,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(*) AS sales_cnt
  FROM call_center cc
  JOIN catalog_returns cr ON cc.cc_call_center_sk = cr.cr_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
                         AND sr.sr_addr_sk = ca.ca_address_sk
                         AND sr.sr_return_time_sk = td.t_time_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                     AND ws.ws_bill_addr_sk = ca.ca_address_sk
                     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
  WHERE cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND td.t_shift = 'first'
    AND c.c_preferred_cust_flag = 'Y'
    AND p.p_discount_active = 'Y'
    AND ws.ws_sales_price > 100
  GROUP BY cc.cc_name, sm.sm_type, td.t_hour, ca.ca_state
),

returns_agg AS (
  SELECT
    cc.cc_name,
    sm.sm_type,
    td.t_hour,
    ca.ca_state,
    SUM(wr.wr_return_amt) AS total_return_amt,
    COUNT(*) AS return_cnt
  FROM call_center cc
  JOIN catalog_returns cr ON cc.cc_call_center_sk = cr.cr_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                     AND ws.ws_bill_addr_sk = ca.ca_address_sk
                     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                        AND wr.wr_item_sk = ws.ws_item_sk
                        AND wr.wr_returned_time_sk = td.t_time_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
  WHERE cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND td.t_shift = 'first'
    AND c.c_preferred_cust_flag = 'Y'
    AND p.p_discount_active = 'Y'
    AND wr.wr_return_amt > 50
  GROUP BY cc.cc_name, sm.sm_type, td.t_hour, ca.ca_state
),

combined AS (
  SELECT
    cc_name,
    sm_type,
    t_hour,
    ca_state,
    total_net_paid,
    sales_cnt,
    CAST(NULL AS double) AS total_return_amt,
    CAST(NULL AS integer) AS return_cnt,
    'sales' AS src
  FROM sales_agg
  UNION ALL
  SELECT
    cc_name,
    sm_type,
    t_hour,
    ca_state,
    CAST(NULL AS double) AS total_net_paid,
    CAST(NULL AS integer) AS sales_cnt,
    total_return_amt,
    return_cnt,
    'returns' AS src
  FROM returns_agg
)
SELECT
  cc_name,
  sm_type,
  t_hour,
  ca_state,
  total_net_paid,
  total_return_amt,
  ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY COALESCE(total_net_paid, 0) DESC) AS rn
FROM combined
WHERE (total_net_paid IS NOT NULL AND total_net_paid > 5000)
   OR (total_return_amt IS NOT NULL AND total_return_amt > 2000)
ORDER BY rn
LIMIT 100
