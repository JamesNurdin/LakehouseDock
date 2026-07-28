WITH
  catalog_branch AS (
    SELECT
      cs.cs_order_number                AS order_number,
      cs.cs_sold_date_sk                AS sold_date_sk,
      cs.cs_ext_sales_price             AS sale_amount,
      cs.cs_net_profit                  AS profit,
      i.i_category                      AS item_category,
      CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM
      catalog_sales cs
      /* time of sale for the catalog transaction */
      JOIN time_dim t_sale ON cs.cs_sold_time_sk = t_sale.t_time_sk
      /* billing customer and its dimensions */
      JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
      JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
      /* item and promotion */
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
      /* call center, catalog page, ship mode, warehouse */
      JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
      JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
      /* inventory for the same item‑warehouse pair */
      JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
      /* store sales (to involve store‑related tables) */
      JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
      JOIN time_dim t_store ON ss.ss_sold_time_sk = t_store.t_time_sk
      JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
      /* exclude catalog orders that have a return */
      NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_order_number = cs.cs_order_number
      )
      AND t_sale.t_shift = 'first'
  ),
  web_branch AS (
    SELECT
      ws.ws_order_number                AS order_number,
      ws.ws_sold_date_sk                AS sold_date_sk,
      ws.ws_ext_sales_price             AS sale_amount,
      ws.ws_net_profit                  AS profit,
      i.i_category                      AS item_category,
      CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM
      web_sales ws
      /* time of sale for the web transaction */
      JOIN time_dim t_sale ON ws.ws_sold_time_sk = t_sale.t_time_sk
      /* billing customer and its dimensions */
      JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
      JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
      JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
      /* item and promotion */
      JOIN item i ON ws.ws_item_sk = i.i_item_sk
      JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
      /* web page, ship mode, warehouse */
      JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
      JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
      /* inventory for the same item‑warehouse pair */
      JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
      /* exclude web orders that have a return */
      NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE wr.wr_order_number = ws.ws_order_number
      )
      AND t_sale.t_shift = 'first'
  ),
  combined AS (
    SELECT * FROM catalog_branch
    UNION ALL
    SELECT * FROM web_branch
  )
SELECT
  order_number,
  sold_date_sk,
  item_category,
  SUM(sale_amount) AS total_sales,
  SUM(profit)      AS total_profit,
  COUNT(*)         AS txn_count,
  MAX(profit_flag) AS any_positive_flag
FROM combined
GROUP BY
  order_number,
  sold_date_sk,
  item_category
ORDER BY total_sales DESC
LIMIT 100
