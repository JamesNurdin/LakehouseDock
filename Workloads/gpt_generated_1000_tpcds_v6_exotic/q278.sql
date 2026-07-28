/* goal: Summarize yearly net sales, profit and inventory by market, ship mode and channel across all sales and return channels */
WITH
  inv_agg AS (
    SELECT
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_date_sk
  ),
  sales_data AS (
    SELECT
      d_sales.d_year AS year,
      cc.cc_mkt_id AS market_id,
      sm_cs.sm_type AS ship_mode,
      'catalog' AS channel,
      SUM(cs.cs_net_paid) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      COALESCE(SUM(ia.total_qty_on_hand), 0) AS inventory_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN inv_agg ia ON d_sales.d_date_sk = ia.inv_date_sk
    GROUP BY d_sales.d_year, cc.cc_mkt_id, sm_cs.sm_type
  ),
  store_data AS (
    SELECT
      d_store.d_year AS year,
      NULL AS market_id,
      NULL AS ship_mode,
      'store' AS channel,
      SUM(ss.ss_net_paid) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COALESCE(SUM(ia.total_qty_on_hand), 0) AS inventory_on_hand
    FROM store_sales ss
    JOIN date_dim d_store ON ss.ss_sold_date_sk = d_store.d_date_sk
    JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
    LEFT JOIN inv_agg ia ON d_store.d_date_sk = ia.inv_date_sk
    GROUP BY d_store.d_year
  ),
  web_data AS (
    SELECT
      d_web.d_year AS year,
      NULL AS market_id,
      sm_ws.sm_type AS ship_mode,
      'web' AS channel,
      SUM(ws.ws_net_paid) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      COALESCE(SUM(ia.total_qty_on_hand), 0) AS inventory_on_hand
    FROM web_sales ws
    JOIN date_dim d_web ON ws.ws_sold_date_sk = d_web.d_date_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    LEFT JOIN inv_agg ia ON d_web.d_date_sk = ia.inv_date_sk
    GROUP BY d_web.d_year, sm_ws.sm_type
  ),
  return_data AS (
    SELECT
      d_ret.d_year AS year,
      cc_ret.cc_mkt_id AS market_id,
      sm_ret.sm_type AS ship_mode,
      'catalog_return' AS channel,
      -SUM(cr.cr_return_amount) AS total_sales,
      -SUM(cr.cr_net_loss) AS total_profit,
      0 AS inventory_on_hand
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
    JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    GROUP BY d_ret.d_year, cc_ret.cc_mkt_id, sm_ret.sm_type
  )
SELECT
  year,
  market_id,
  ship_mode,
  channel,
  total_sales,
  total_profit,
  inventory_on_hand
FROM (
  SELECT year, market_id, ship_mode, channel, total_sales, total_profit, inventory_on_hand FROM sales_data
  UNION ALL
  SELECT year, market_id, ship_mode, channel, total_sales, total_profit, inventory_on_hand FROM store_data
  UNION ALL
  SELECT year, market_id, ship_mode, channel, total_sales, total_profit, inventory_on_hand FROM web_data
  UNION ALL
  SELECT year, market_id, ship_mode, channel, total_sales, total_profit, inventory_on_hand FROM return_data
) AS final_result
ORDER BY year DESC, total_sales DESC
LIMIT 100
