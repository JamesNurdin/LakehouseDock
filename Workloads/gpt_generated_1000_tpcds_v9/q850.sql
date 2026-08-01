WITH catalog_agg AS (
  SELECT
    c.c_customer_id,
    c.c_customer_sk,
    p.p_promo_name,
    s.s_store_name,
    cp.cp_department,
    sm.sm_type AS ship_mode_type,
    SUM(cs.cs_net_paid) AS total_sales_amount,
    AVG(cs.cs_net_profit) AS avg_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    'catalog' AS sales_channel
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE cc.cc_rec_start_date > DATE '2000-01-01'
    AND p.p_channel_radio = 'N'
    AND ib.ib_lower_bound >= 50000
    AND s.s_country = 'United States'
  GROUP BY c.c_customer_id, c.c_customer_sk, p.p_promo_name, s.s_store_name, cp.cp_department, sm.sm_type
),

web_agg AS (
  SELECT
    c.c_customer_id,
    c.c_customer_sk,
    p.p_promo_name,
    s.s_store_name,
    CAST(NULL AS varchar) AS cp_department,
    sm.sm_type AS ship_mode_type,
    SUM(ws.ws_net_paid) AS total_sales_amount,
    AVG(ws.ws_net_profit) AS avg_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    'web' AS sales_channel
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE p.p_channel_radio = 'N'
    AND ib.ib_lower_bound >= 50000
    AND s.s_country = 'United States'
  GROUP BY c.c_customer_id, c.c_customer_sk, p.p_promo_name, s.s_store_name, sm.sm_type
),

combined_sales AS (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM web_agg
)

SELECT
  cs.c_customer_id,
  cs.c_customer_sk,
  cs.p_promo_name,
  cs.s_store_name,
  cs.ship_mode_type,
  cs.total_sales_amount,
  cs.avg_profit,
  cs.order_count,
  cs.sales_channel,
  (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = cs.c_customer_sk) AS total_store_returns,
  (SELECT AVG(ws2.ws_net_paid) FROM web_sales ws2 WHERE ws2.ws_bill_customer_sk = cs.c_customer_sk) AS avg_web_net_paid
FROM combined_sales cs
ORDER BY cs.total_sales_amount DESC
LIMIT 100
