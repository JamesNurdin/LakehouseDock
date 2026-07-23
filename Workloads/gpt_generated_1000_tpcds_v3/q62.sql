SELECT
  d_cr.d_year AS year,
  w1.w_city AS city,
  i.i_category AS category,
  ib.ib_income_band_sk AS income_band_sk,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(sr.sr_return_amt) AS total_store_return_amount,
  SUM(wr.wr_return_amt) AS total_web_return_amount,
  SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
  SUM(sr.sr_return_quantity) AS total_store_return_qty,
  SUM(wr.wr_return_quantity) AS total_web_return_qty,
  AVG(sr.sr_fee) AS avg_store_return_fee,
  MAX(inv.inv_quantity_on_hand) AS max_inventory_on_hand,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
  MIN(p.p_cost) AS min_promo_cost,
  MAX(p.p_cost) AS max_promo_cost
FROM catalog_returns cr
INNER JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
INNER JOIN item i ON cr.cr_item_sk = i.i_item_sk
INNER JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN warehouse w1 ON cr.cr_warehouse_sk = w1.w_warehouse_sk
INNER JOIN promotion p ON p.p_item_sk = i.i_item_sk
INNER JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
INNER JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
INNER JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
INNER JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_hdemo_sk = hd.hd_demo_sk
INNER JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
INNER JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
INNER JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
WHERE d_cr.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND w1.w_city = 'Riverside'
  AND w1.w_gmt_offset = -5.00
  AND p.p_channel_tv = 'N'
  AND ib.ib_lower_bound >= 50000
  AND hd.hd_vehicle_count >= 2
  AND sr.sr_fee > 20.0
GROUP BY d_cr.d_year, w1.w_city, i.i_category, ib.ib_income_band_sk
ORDER BY total_catalog_return_amount DESC
LIMIT 100
