WITH base AS (
  SELECT
    d.d_year,
    d.d_date,
    i.i_item_sk,
    i.i_category,
    i.i_product_name,
    cs.cs_net_paid,
    cs.cs_ext_discount_amt,
    cr.cr_return_amount,
    ws.ws_net_paid,
    sr.sr_return_amt,
    inv.inv_quantity_on_hand,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cc.cc_name,
    cp.cp_type,
    sm.sm_type,
    w.w_warehouse_name,
    p.p_discount_active,
    r.r_reason_desc,
    s.s_store_name,
    wp.wp_type,
    we.web_name,
    (
      SELECT AVG(inv2.inv_quantity_on_hand)
      FROM inventory inv2
      WHERE inv2.inv_item_sk = i.i_item_sk
        AND inv2.inv_date_sk = d.d_date_sk
    ) AS avg_inv_qty
  FROM date_dim d
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_order_number = cs.cs_order_number
  LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_item_sk = i.i_item_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_item_sk = i.i_item_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
  LEFT JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
  LEFT JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
  LEFT JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
  LEFT JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
)
SELECT DISTINCT
  base.d_year,
  base.s_store_name,
  base.i_category,
  SUM(base.cs_net_paid) AS total_catalog_sales,
  SUM(COALESCE(base.cr_return_amount, 0)) AS total_catalog_returns,
  SUM(COALESCE(base.ws_net_paid, 0)) AS total_web_sales,
  SUM(COALESCE(base.sr_return_amt, 0)) AS total_store_returns,
  AVG(base.cs_ext_discount_amt) AS avg_discount_amount,
  AVG(base.avg_inv_qty) AS avg_inventory_quantity,
  COUNT(DISTINCT base.i_item_sk) AS distinct_items_sold
FROM base
WHERE
  base.d_year = 2000
  AND base.cc_name = 'Call Center 1'
  AND base.p_discount_active = 'Y'
GROUP BY
  base.d_year,
  base.s_store_name,
  base.i_category
ORDER BY
  total_catalog_sales DESC,
  base.s_store_name
LIMIT 100
