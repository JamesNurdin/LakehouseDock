WITH
  cs_fact AS (
    SELECT
      cs.cs_item_sk,
      i.i_category,
      i.i_brand,
      cs.cs_net_profit AS catalog_profit,
      w.w_state AS warehouse_state,
      cc.cc_name AS call_center_name,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      sm.sm_type AS ship_mode_type
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  ),
  cr_fact AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      r.r_reason_desc,
      cc.cc_name AS return_call_center,
      w.w_state AS return_warehouse_state,
      sm.sm_type AS return_ship_mode_type
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  ),
  ss_fact AS (
    SELECT
      ss.ss_item_sk,
      i2.i_category,
      i2.i_brand,
      ss.ss_net_profit AS store_profit,
      s.s_state AS store_state,
      hd2.hd_income_band_sk
    FROM store_sales ss
    JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
    JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
  ),
  ws_fact AS (
    SELECT
      ws.ws_item_sk,
      i3.i_category,
      i3.i_brand,
      ws.ws_net_profit AS web_profit,
      w3.w_state AS warehouse_state,
      wp.wp_type AS page_type,
      hd3.hd_income_band_sk,
      sm3.sm_type AS ship_mode_type
    FROM web_sales ws
    JOIN item i3 ON ws.ws_item_sk = i3.i_item_sk
    JOIN household_demographics hd3 ON ws.ws_bill_hdemo_sk = hd3.hd_demo_sk
    JOIN warehouse w3 ON ws.ws_warehouse_sk = w3.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm3 ON ws.ws_ship_mode_sk = sm3.sm_ship_mode_sk
  ),
  inv_fact AS (
    SELECT
      inv.inv_item_sk,
      SUM(inv.inv_quantity_on_hand) AS inventory_qty,
      w_inv.w_state AS inventory_warehouse_state
    FROM inventory inv
    JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    JOIN item i4 ON inv.inv_item_sk = i4.i_item_sk
    GROUP BY inv.inv_item_sk, w_inv.w_state
  ),
  cs_agg AS (
    SELECT
      cs_item_sk,
      SUM(catalog_profit) AS catalog_profit,
      MIN(ib_lower_bound) AS ib_lower_bound,
      MIN(ib_upper_bound) AS ib_upper_bound,
      MIN(warehouse_state) AS catalog_warehouse_state
    FROM cs_fact
    GROUP BY cs_item_sk
  ),
  ss_agg AS (
    SELECT
      ss_item_sk,
      SUM(store_profit) AS store_profit,
      MIN(store_state) AS store_state
    FROM ss_fact
    GROUP BY ss_item_sk
  ),
  ws_agg AS (
    SELECT
      ws_item_sk,
      SUM(web_profit) AS web_profit,
      MIN(warehouse_state) AS web_warehouse_state,
      MIN(page_type) AS page_type
    FROM ws_fact
    GROUP BY ws_item_sk
  )
SELECT
  i.i_item_id,
  i.i_category,
  i.i_brand,
  COALESCE(cs_agg.catalog_profit, 0) AS catalog_profit,
  COALESCE(ss_agg.store_profit, 0) AS store_profit,
  COALESCE(ws_agg.web_profit, 0) AS web_profit,
  COALESCE(cs_agg.catalog_profit, 0) + COALESCE(ss_agg.store_profit, 0) + COALESCE(ws_agg.web_profit, 0) AS total_profit,
  ROW_NUMBER() OVER (ORDER BY COALESCE(cs_agg.catalog_profit, 0) + COALESCE(ss_agg.store_profit, 0) + COALESCE(ws_agg.web_profit, 0) DESC) AS profit_rank,
  cs_agg.ib_lower_bound,
  cs_agg.ib_upper_bound,
  inv_fact.inventory_qty,
  inv_fact.inventory_warehouse_state,
  cs_agg.catalog_warehouse_state,
  ss_agg.store_state,
  ws_agg.web_warehouse_state,
  ws_agg.page_type
FROM item i
LEFT JOIN cs_agg ON i.i_item_sk = cs_agg.cs_item_sk
LEFT JOIN ss_agg ON i.i_item_sk = ss_agg.ss_item_sk
LEFT JOIN ws_agg ON i.i_item_sk = ws_agg.ws_item_sk
LEFT JOIN inv_fact ON i.i_item_sk = inv_fact.inv_item_sk
GROUP BY
  i.i_item_id,
  i.i_category,
  i.i_brand,
  cs_agg.catalog_profit,
  ss_agg.store_profit,
  ws_agg.web_profit,
  cs_agg.ib_lower_bound,
  cs_agg.ib_upper_bound,
  inv_fact.inventory_qty,
  inv_fact.inventory_warehouse_state,
  cs_agg.catalog_warehouse_state,
  ss_agg.store_state,
  ws_agg.web_warehouse_state,
  ws_agg.page_type
ORDER BY total_profit DESC
LIMIT 100
