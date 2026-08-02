WITH catalog_sales_agg AS (
  SELECT
    cs_item_sk,
    cs_promo_sk,
    cs_catalog_page_sk,
    cs_sold_date_sk,
    cs_ship_date_sk,
    cs_ship_mode_sk,
    cs_warehouse_sk,
    cs_bill_hdemo_sk,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cs_quantity) AS total_quantity
  FROM tpcds.catalog_sales
  GROUP BY cs_item_sk, cs_promo_sk, cs_catalog_page_sk, cs_sold_date_sk, cs_ship_date_sk,
           cs_ship_mode_sk, cs_warehouse_sk, cs_bill_hdemo_sk
),
web_sales_agg AS (
  SELECT
    ws_item_sk,
    ws_promo_sk,
    ws_web_site_sk,
    ws_sold_date_sk,
    ws_ship_date_sk,
    ws_ship_mode_sk,
    ws_warehouse_sk,
    ws_bill_hdemo_sk,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(ws_quantity) AS total_quantity
  FROM tpcds.web_sales
  GROUP BY ws_item_sk, ws_promo_sk, ws_web_site_sk, ws_sold_date_sk, ws_ship_date_sk,
           ws_ship_mode_sk, ws_warehouse_sk, ws_bill_hdemo_sk
)
SELECT
  'Catalog' AS sales_channel,
  i_c.i_item_id AS item_id,
  i_c.i_item_desc AS item_desc,
  i_c.i_category AS item_category,
  CASE WHEN i_c.i_current_price > 100 THEN 'Premium' ELSE 'Standard' END AS price_category,
  p_c.p_promo_name AS promo_name,
  d_sold_c.d_date AS sold_date,
  d_ship_c.d_date AS ship_date,
  pd_c.promo_duration_days,
  seg_c.segment,
  s_c.s_store_name AS store_name,
  s_c.s_market_id AS market_id,
  CONCAT(CAST(ib_c.ib_lower_bound AS VARCHAR), '-', CAST(ib_c.ib_upper_bound AS VARCHAR)) AS income_band_range,
  cs.total_net_paid
FROM catalog_sales_agg cs
JOIN tpcds.item i_c ON cs.cs_item_sk = i_c.i_item_sk
JOIN tpcds.promotion p_c ON cs.cs_promo_sk = p_c.p_promo_sk
JOIN tpcds.catalog_page cp_c ON cs.cs_catalog_page_sk = cp_c.cp_catalog_page_sk
JOIN tpcds.ship_mode sm_c ON cs.cs_ship_mode_sk = sm_c.sm_ship_mode_sk
JOIN tpcds.warehouse w_c ON cs.cs_warehouse_sk = w_c.w_warehouse_sk
JOIN tpcds.date_dim d_sold_c ON cs.cs_sold_date_sk = d_sold_c.d_date_sk
JOIN tpcds.date_dim d_ship_c ON cs.cs_ship_date_sk = d_ship_c.d_date_sk
JOIN tpcds.store s_c ON s_c.s_closed_date_sk = d_ship_c.d_date_sk
JOIN tpcds.household_demographics hd_c ON cs.cs_bill_hdemo_sk = hd_c.hd_demo_sk
JOIN tpcds.income_band ib_c ON hd_c.hd_income_band_sk = ib_c.ib_income_band_sk
JOIN tpcds.date_dim d_promo_start_c ON p_c.p_start_date_sk = d_promo_start_c.d_date_sk
JOIN tpcds.date_dim d_promo_end_c ON p_c.p_end_date_sk = d_promo_end_c.d_date_sk
CROSS JOIN LATERAL (
    SELECT date_diff('day', d_promo_start_c.d_date, d_promo_end_c.d_date) AS promo_duration_days
) pd_c
CROSS JOIN LATERAL (
    SELECT CASE WHEN cs.total_net_paid > 5000 THEN 'VIP' ELSE 'Regular' END AS segment
) seg_c
UNION ALL
SELECT
  'Web' AS sales_channel,
  i_w.i_item_id AS item_id,
  i_w.i_item_desc AS item_desc,
  i_w.i_category AS item_category,
  CASE WHEN i_w.i_current_price > 100 THEN 'Premium' ELSE 'Standard' END AS price_category,
  p_w.p_promo_name AS promo_name,
  d_sold_w.d_date AS sold_date,
  d_ship_w.d_date AS ship_date,
  pd_w.promo_duration_days,
  seg_w.segment,
  s_w.s_store_name AS store_name,
  s_w.s_market_id AS market_id,
  CONCAT(CAST(ib_w.ib_lower_bound AS VARCHAR), '-', CAST(ib_w.ib_upper_bound AS VARCHAR)) AS income_band_range,
  ws.total_net_paid
FROM web_sales_agg ws
JOIN tpcds.item i_w ON ws.ws_item_sk = i_w.i_item_sk
JOIN tpcds.promotion p_w ON ws.ws_promo_sk = p_w.p_promo_sk
JOIN tpcds.web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN tpcds.ship_mode sm_w ON ws.ws_ship_mode_sk = sm_w.sm_ship_mode_sk
JOIN tpcds.warehouse w_w ON ws.ws_warehouse_sk = w_w.w_warehouse_sk
JOIN tpcds.date_dim d_sold_w ON ws.ws_sold_date_sk = d_sold_w.d_date_sk
JOIN tpcds.date_dim d_ship_w ON ws.ws_ship_date_sk = d_ship_w.d_date_sk
JOIN tpcds.store s_w ON s_w.s_closed_date_sk = d_ship_w.d_date_sk
JOIN tpcds.household_demographics hd_w ON ws.ws_bill_hdemo_sk = hd_w.hd_demo_sk
JOIN tpcds.income_band ib_w ON hd_w.hd_income_band_sk = ib_w.ib_income_band_sk
JOIN tpcds.date_dim d_promo_start_w ON p_w.p_start_date_sk = d_promo_start_w.d_date_sk
JOIN tpcds.date_dim d_promo_end_w ON p_w.p_end_date_sk = d_promo_end_w.d_date_sk
CROSS JOIN LATERAL (
    SELECT date_diff('day', d_promo_start_w.d_date, d_promo_end_w.d_date) AS promo_duration_days
) pd_w
CROSS JOIN LATERAL (
    SELECT CASE WHEN ws.total_net_paid > 5000 THEN 'VIP' ELSE 'Regular' END AS segment
) seg_w
ORDER BY total_net_paid DESC, sales_channel
LIMIT 100
