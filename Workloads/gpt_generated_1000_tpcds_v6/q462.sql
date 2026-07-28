WITH ss_agg AS (
  SELECT 
    ss_customer_sk,
    ss_sold_date_sk,
    SUM(ss_net_paid)               AS total_net_paid,
    SUM(ss_quantity)               AS total_quantity,
    COUNT(*)                       AS sales_cnt
  FROM store_sales
  WHERE ss_net_paid > 0
  GROUP BY ss_customer_sk, ss_sold_date_sk
),
cs_agg AS (
  SELECT 
    cs_order_number,
    cs_bill_customer_sk,
    cs_sold_date_sk,
    cs_sold_time_sk,
    cs_call_center_sk,
    cs_promo_sk,
    cs_catalog_page_sk,
    SUM(cs_net_paid)               AS cs_total_paid,
    SUM(cs_quantity)               AS cs_total_qty
  FROM catalog_sales
  WHERE cs_net_paid > 0
  GROUP BY cs_order_number, cs_bill_customer_sk, cs_sold_date_sk, cs_sold_time_sk,
           cs_call_center_sk, cs_promo_sk, cs_catalog_page_sk
)
SELECT
  c.c_customer_id,
  d_sold.d_date                           AS sales_date,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ss_agg.total_net_paid,
  cs_agg.cs_total_paid,
  COALESCE(cr.cr_return_amount, 0)       AS return_amount,
  CASE 
    WHEN ss_agg.total_net_paid > 10000 THEN 'HIGH'
    WHEN ss_agg.total_net_paid BETWEEN 5000 AND 10000 THEN 'MEDIUM'
    ELSE 'LOW'
  END                                    AS spend_category,
  ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY ss_agg.total_net_paid DESC) AS spend_rank,
  pc.p_promo_name,
  sm.sm_carrier,
  wc.web_name,
  wp.wp_url,
  cc.cc_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM call_center cc2 
      WHERE cc2.cc_call_center_sk = cs_agg.cs_call_center_sk 
        AND cc2.cc_state = 'CA'
    ) THEN 'CA_CALL' 
    ELSE 'OTHER' 
  END                                    AS call_center_region
FROM ss_agg
JOIN customer c
  ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN date_dim d_sold
  ON ss_agg.ss_sold_date_sk = d_sold.d_date_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN cs_agg
  ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
  AND cs_agg.cs_sold_date_sk = ss_agg.ss_sold_date_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_order_number = cs_agg.cs_order_number
LEFT JOIN promotion pc
  ON cs_agg.cs_promo_sk = pc.p_promo_sk
LEFT JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_site wc
  ON wc.web_open_date_sk = d_sold.d_date_sk
LEFT JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
  AND wp.wp_creation_date_sk = d_sold.d_date_sk
LEFT JOIN call_center cc
  ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
  ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim t
  ON cs_agg.cs_sold_time_sk = t.t_time_sk
WHERE 
  d_sold.d_year = 2001
  AND hd.hd_vehicle_count >= 1
  AND ib.ib_lower_bound >= 20000
  AND pc.p_discount_active = 'Y'
  AND sm.sm_carrier = 'UPS'
  AND cp.cp_type = 'C'
  AND t.t_hour BETWEEN 8 AND 17
GROUP BY
  c.c_customer_id,
  d_sold.d_date,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ss_agg.total_net_paid,
  cs_agg.cs_total_paid,
  cr.cr_return_amount,
  pc.p_promo_name,
  sm.sm_carrier,
  wc.web_name,
  wp.wp_url,
  cc.cc_name,
  CASE 
    WHEN ss_agg.total_net_paid > 10000 THEN 'HIGH'
    WHEN ss_agg.total_net_paid BETWEEN 5000 AND 10000 THEN 'MEDIUM'
    ELSE 'LOW'
  END,
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM call_center cc2 
      WHERE cc2.cc_call_center_sk = cs_agg.cs_call_center_sk 
        AND cc2.cc_state = 'CA'
    ) THEN 'CA_CALL' 
    ELSE 'OTHER' 
  END,
  hd.hd_buy_potential
HAVING 
  SUM(ss_agg.total_net_paid) > 5000
ORDER BY 
  ss_agg.total_net_paid DESC,
  c.c_customer_id
LIMIT 100
