/* Goal: Analyze combined catalog sales, store returns, and web sales by call center, catalog page, ship mode, and hour part of the call center's business hours, categorizing profit levels, applying multiple realistic filters, and incorporating promotional performance, while demonstrating advanced SQL features such as CTEs, UNION, EXISTS, scalar sub‑query, CASE, DISTINCT, and UNNEST. */
WITH
  promo_agg AS (
    SELECT
      p.p_promo_id,
      SUM(cs.cs_ext_sales_price) AS promo_sales_amount,
      COUNT(*) AS promo_sales_cnt
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id
  ),
  union_entities AS (
    SELECT DISTINCT p.p_promo_sk AS entity_key
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
    UNION
    SELECT DISTINCT web.web_site_sk AS entity_key
    FROM web_site web
    WHERE web.web_state = 'CA'
  )
SELECT
  cc.cc_name,
  cp.cp_department,
  sm.sm_carrier,
  t.hour_part,
  CASE
    WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
    WHEN cs.cs_net_profit BETWEEN 0 AND 1000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
  SUM(sr.sr_return_amt) AS total_store_returns,
  SUM(ws.ws_ext_sales_price) AS total_web_sales,
  COUNT(DISTINCT cs.cs_order_number) AS unique_order_cnt,
  (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_catalog_net_profit,
  pa.promo_sales_amount,
  pa.promo_sales_cnt
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_item_sk = cs.cs_item_sk
  AND cr.cr_order_number = cs.cs_order_number
LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
LEFT JOIN catalog_page cp_cr ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
LEFT JOIN call_center cc_cr ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
LEFT JOIN store_returns sr
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
  AND sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN web_sales ws
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
LEFT JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
LEFT JOIN promo_agg pa ON p.p_promo_id = pa.p_promo_id
CROSS JOIN UNNEST(split(cc.cc_hours, ',')) AS t(hour_part)
WHERE
  cc.cc_state = 'CA'
  AND cp.cp_department = 'Electronics'
  AND sm.sm_carrier = 'BARIAN'
  AND cd.cd_purchase_estimate BETWEEN 5000 AND 8000
  AND hd.hd_income_band_sk = 5
  AND cs.cs_quantity > 5
  AND cs.cs_net_profit > 0
  AND p.p_discount_active = 'Y'
  AND web.web_country = 'United States'
  AND w.w_state = 'CA'
  AND cs.cs_promo_sk IN (SELECT entity_key FROM union_entities)
  AND EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_return_amount > 100
      AND cr2.cr_order_number = cs.cs_order_number
  )
GROUP BY
  cc.cc_name,
  cp.cp_department,
  sm.sm_carrier,
  t.hour_part,
  CASE
    WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
    WHEN cs.cs_net_profit BETWEEN 0 AND 1000 THEN 'MEDIUM'
    ELSE 'LOW'
  END,
  pa.promo_sales_amount,
  pa.promo_sales_cnt
ORDER BY total_catalog_sales DESC
LIMIT 100
