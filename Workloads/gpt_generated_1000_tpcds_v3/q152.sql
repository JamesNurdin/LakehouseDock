/*
Goal: Summarize catalog sales by promotion and ship mode for items whose catalog page description mentions a discount. The query extracts the numeric part of the promotion ID using a regular expression, filters promotions whose names contain "summer" or "holiday" (case‑insensitive), classifies profit as Profitable or Loss, and shows a sample customer name and a short description snippet. Results are ordered by total net profit and limited to the top 100 rows.
*/
SELECT
  p.p_promo_name,
  ship.sm_ship_mode_id,
  regexp_extract(p.p_promo_id, '\\d+', 0) AS promo_id_numeric,
  COUNT(*) AS sales_cnt,
  SUM(cs.cs_quantity) AS total_qty,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_net_profit) AS total_net_profit,
  CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
  MAX(concat(c.c_first_name, ' ', c.c_last_name)) AS sample_customer_name,
  MAX(substring(cp.cp_description, 1, 30)) AS short_description,
  MAX(CASE WHEN length(cp.cp_description) > 100 THEN 'Long' ELSE 'Short' END) AS description_len_category
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode ship ON cs.cs_ship_mode_sk = ship.sm_ship_mode_sk
JOIN warehouse wh ON cs.cs_warehouse_sk = wh.w_warehouse_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
WHERE cp.cp_description LIKE '%discount%'
  AND regexp_like(p.p_promo_name, '(?i)summer|holiday')
  AND td.t_hour >= 9 AND td.t_hour < 18
GROUP BY
  p.p_promo_name,
  ship.sm_ship_mode_id,
  regexp_extract(p.p_promo_id, '\\d+', 0)
ORDER BY total_net_profit DESC
LIMIT 100
