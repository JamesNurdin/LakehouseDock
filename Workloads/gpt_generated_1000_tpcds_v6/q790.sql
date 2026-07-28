WITH
  sales_agg AS (
    SELECT
      i.i_item_id,
      i.i_color,
      p.p_promo_id,
      w.w_state,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      SUM(cs.cs_net_paid) AS total_sales,
      COUNT(*) AS sales_transactions,
      SUM(cs.cs_quantity) AS total_quantity,
      CASE WHEN SUM(cs.cs_quantity) > 0 THEN SUM(cs.cs_net_paid) / SUM(cs.cs_quantity) ELSE 0 END AS avg_price
    FROM catalog_sales cs
      JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
      JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
      JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
      JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_hdemo_sk = hd.hd_demo_sk AND ss.ss_promo_sk = p.p_promo_sk
      JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk AND ws.ws_promo_sk = p.p_promo_sk
    WHERE i.i_color = 'papaya'
      AND p.p_cost > 500
      AND i.i_rec_start_date >= DATE '2000-01-01'
    GROUP BY i.i_item_id, i.i_color, p.p_promo_id, w.w_state, hd.hd_income_band_sk, ib.ib_lower_bound
  ),
  returns_agg AS (
    SELECT
      i.i_item_id,
      i.i_color,
      p.p_promo_id,
      w.w_state,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      SUM(cr.cr_return_amount) AS total_returns,
      COUNT(*) AS return_transactions,
      SUM(cr.cr_return_quantity) AS total_return_qty,
      CASE WHEN SUM(cr.cr_return_quantity) > 0 THEN SUM(cr.cr_return_amount) / SUM(cr.cr_return_quantity) ELSE 0 END AS avg_return_price
    FROM catalog_returns cr
      JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
      JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN item i ON cr.cr_item_sk = i.i_item_sk
      JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
      JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
      JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
      JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_hdemo_sk = hd.hd_demo_sk AND ss.ss_promo_sk = p.p_promo_sk
      JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk AND ws.ws_promo_sk = p.p_promo_sk
    WHERE i.i_color = 'papaya'
      AND p.p_cost > 500
      AND i.i_rec_start_date >= DATE '2000-01-01'
    GROUP BY i.i_item_id, i.i_color, p.p_promo_id, w.w_state, hd.hd_income_band_sk, ib.ib_lower_bound
  ),
  combined AS (
    SELECT
      i_item_id,
      i_color,
      p_promo_id,
      w_state,
      hd_income_band_sk,
      ib_lower_bound,
      total_sales,
      sales_transactions,
      total_quantity,
      avg_price,
      NULL AS total_returns,
      NULL AS return_transactions,
      NULL AS total_return_qty,
      NULL AS avg_return_price,
      NULL AS return_ratio
    FROM sales_agg
    UNION ALL
    SELECT
      i_item_id,
      i_color,
      p_promo_id,
      w_state,
      hd_income_band_sk,
      ib_lower_bound,
      NULL,
      NULL,
      NULL,
      NULL,
      total_returns,
      return_transactions,
      total_return_qty,
      avg_return_price,
      NULL
    FROM returns_agg
  )
SELECT
  i_item_id,
  i_color,
  p_promo_id,
  w_state,
  hd_income_band_sk,
  ib_lower_bound,
  total_sales,
  sales_transactions,
  total_quantity,
  avg_price,
  total_returns,
  return_transactions,
  total_return_qty,
  avg_return_price,
  CASE WHEN total_sales IS NOT NULL AND total_sales > 0 THEN total_returns / total_sales ELSE NULL END AS return_ratio
FROM combined
ORDER BY total_sales DESC NULLS LAST
LIMIT 100
