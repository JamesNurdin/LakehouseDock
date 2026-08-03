WITH catalog_agg AS (
  SELECT
    p.p_promo_id AS promo_id,
    w.w_warehouse_name AS warehouse_name,
    hd.hd_income_band_sk AS income_band,
    r.r_reason_desc AS reason_desc,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    CASE WHEN SUM(cs.cs_net_paid) > SUM(COALESCE(cr.cr_return_amount, 0)) THEN 1 ELSE 0 END AS profit_flag,
    CAST(NULL AS varchar) AS net_status
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number AND cs.cs_item_sk = cr.cr_item_sk
  LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cs.cs_quantity > 1
    AND cs.cs_net_paid > 100
    AND cs.cs_ext_discount_amt < 50
    AND w.w_gmt_offset BETWEEN -5 AND 5
    AND hd.hd_vehicle_count >= 2
  GROUP BY p.p_promo_id, w.w_warehouse_name, hd.hd_income_band_sk, r.r_reason_desc
),
store_agg AS (
  SELECT
    p.p_promo_id AS promo_id,
    CAST(NULL AS varchar) AS warehouse_name,
    hd.hd_income_band_sk AS income_band,
    r.r_reason_desc AS reason_desc,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    CASE WHEN SUM(ss.ss_net_paid) > SUM(COALESCE(sr.sr_return_amt, 0)) THEN 1 ELSE 0 END AS profit_flag,
    CASE WHEN (SUM(ss.ss_net_paid) - SUM(COALESCE(sr.sr_return_amt, 0))) > 0 THEN 'POS' ELSE 'NEG' END AS net_status
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE ss.ss_quantity > 2
    AND ss.ss_net_paid > 50
    AND hd.hd_dep_count <= 3
    AND (sr.sr_return_amt IS NULL OR sr.sr_return_amt > 5)
  GROUP BY p.p_promo_id, hd.hd_income_band_sk, r.r_reason_desc
),
combined AS (
  SELECT * FROM catalog_agg
  UNION
  SELECT * FROM store_agg
),
filtered AS (
  SELECT
    *,
    (SELECT COUNT(*) FROM web_page wp WHERE wp.wp_type = 'product') AS product_page_count
  FROM combined
  WHERE profit_flag = 1
    AND promo_id IN (SELECT p_promo_id FROM promotion WHERE p_discount_active = 'Y')
    AND total_net_paid > (SELECT AVG(total_net_paid) FROM combined)
)
SELECT
  promo_id,
  warehouse_name,
  income_band,
  reason_desc,
  total_net_paid,
  total_return_amount,
  profit_flag,
  net_status,
  product_page_count
FROM filtered
EXCEPT
SELECT
  promo_id,
  warehouse_name,
  income_band,
  reason_desc,
  total_net_paid,
  total_return_amount,
  profit_flag,
  net_status,
  product_page_count
FROM filtered
WHERE net_status = 'NEG'
ORDER BY total_net_paid DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
