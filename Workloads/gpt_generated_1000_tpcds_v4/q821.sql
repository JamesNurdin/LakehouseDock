WITH sales_filtered AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_ext_sales_price,
    cs.cs_sold_time_sk,
    cs.cs_promo_sk,
    cs.cs_warehouse_sk,
    cs.cs_call_center_sk,
    cs.cs_catalog_page_sk,
    cs.cs_ship_mode_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_bill_addr_sk
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE td.t_hour = 14
    AND p.p_purpose = 'Unknown'
    AND w.w_county = 'Mobile County'
    AND cc.cc_state = 'CA'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
          AND cr.cr_return_amount > 1000
    )
)
SELECT
  p.p_promo_id,
  w.w_warehouse_name,
  SUM(sf.cs_net_profit) AS total_net_profit,
  AVG(sf.cs_ext_sales_price) AS avg_ext_sales_price,
  COUNT(DISTINCT sf.cs_order_number) AS order_cnt,
  MIN(sf.cs_sold_date_sk) AS first_sold_date_sk,
  (SELECT AVG(cr.cr_return_amount) FROM catalog_returns cr) AS avg_return_amount_overall,
  SUM(CASE WHEN cr.cr_return_amount > (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) THEN cr.cr_return_amount ELSE 0 END) AS high_return_amount_sum
FROM sales_filtered sf
JOIN catalog_returns cr ON cr.cr_order_number = sf.cs_order_number
JOIN promotion p ON sf.cs_promo_sk = p.p_promo_sk
JOIN warehouse w ON sf.cs_warehouse_sk = w.w_warehouse_sk
GROUP BY p.p_promo_id, w.w_warehouse_name
ORDER BY total_net_profit DESC
LIMIT 20
