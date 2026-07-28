WITH
  hd_bill AS (
    SELECT hd_demo_sk, hd_income_band_sk, hd_buy_potential, hd_dep_count, hd_vehicle_count
    FROM household_demographics
  ),
  hd_ship AS (
    SELECT hd_demo_sk, hd_income_band_sk, hd_buy_potential, hd_dep_count, hd_vehicle_count
    FROM household_demographics
  ),
  d_sold AS (
    SELECT d_date_sk, d_year, d_month_seq, d_date
    FROM date_dim
  ),
  d_ship AS (
    SELECT d_date_sk, d_year AS ship_year, d_date AS ship_date
    FROM date_dim
  ),
  d_return AS (
    SELECT d_date_sk, d_year AS return_year, d_date AS return_date
    FROM date_dim
  ),
  d_promo_start AS (
    SELECT d_date_sk, d_date AS promo_start_date
    FROM date_dim
  ),
  d_promo_end AS (
    SELECT d_date_sk, d_date AS promo_end_date
    FROM date_dim
  )
SELECT
  s.s_store_name,
  s.s_market_id,
  cc.cc_name,
  p.p_promo_name,
  COUNT(DISTINCT cc.cc_call_center_id) AS distinct_call_centers,
  SUM(cs.cs_net_profit)               AS total_net_profit,
  SUM(cs.cs_quantity)                AS total_quantity,
  AVG(cs.cs_ext_discount_amt)        AS avg_discount_amount,
  SUM(wr.wr_return_amt)              AS total_return_amount,
  SUM(inv.inv_quantity_on_hand)      AS total_inventory_on_hand
FROM catalog_sales cs
JOIN d_sold dsold
  ON cs.cs_sold_date_sk = dsold.d_date_sk
JOIN d_ship dship
  ON cs.cs_ship_date_sk = dship.d_date_sk
JOIN hd_bill hb
  ON cs.cs_bill_hdemo_sk = hb.hd_demo_sk
JOIN hd_ship hs
  ON cs.cs_ship_hdemo_sk = hs.hd_demo_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN d_promo_start dpstart
  ON p.p_start_date_sk = dpstart.d_date_sk
JOIN d_promo_end dpend
  ON p.p_end_date_sk = dpend.d_date_sk
JOIN inventory inv
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
 AND inv.inv_date_sk = dship.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = dship.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = dship.d_date_sk
JOIN d_return dret
  ON wr.wr_returned_date_sk = dret.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = dret.d_date_sk
WHERE dsold.d_year = 2001
  AND p.p_discount_active = 'Y'
GROUP BY
  s.s_store_name,
  s.s_market_id,
  cc.cc_name,
  p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
