WITH
cat_sales AS (
    SELECT
        d_sold.d_year AS year,
        w.w_warehouse_name AS warehouse,
        SUM(cs.cs_net_profit) AS cat_net_profit,
        SUM(cs.cs_quantity) AS cat_qty,
        COUNT(DISTINCT i.i_item_sk) AS cat_distinct_items
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.item i
      ON cs.cs_item_sk = i.i_item_sk
    WHERE d_sold.d_year = 2001
    GROUP BY d_sold.d_year, w.w_warehouse_name
),
web_sales AS (
    SELECT
        d_ws_sold.d_year AS year,
        w_ws.w_warehouse_name AS warehouse,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_qty,
        COUNT(DISTINCT i_ws.i_item_sk) AS web_distinct_items
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d_ws_sold
      ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN tpcds.time_dim t_ws_sold
      ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN tpcds.ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN tpcds.warehouse w_ws
      ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN tpcds.item i_ws
      ON ws.ws_item_sk = i_ws.i_item_sk
    JOIN tpcds.web_page wp_ws
      ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
    WHERE d_ws_sold.d_year = 2001
    GROUP BY d_ws_sold.d_year, w_ws.w_warehouse_name
),
cat_returns AS (
    SELECT
        d_ret.d_year AS year,
        w_ret.w_warehouse_name AS warehouse,
        SUM(cr.cr_net_loss) AS cat_return_loss,
        COUNT(DISTINCT i_ret.i_item_sk) AS cat_ret_distinct_items
    FROM tpcds.catalog_returns cr
    JOIN tpcds.catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN tpcds.time_dim t_ret
      ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN tpcds.item i_ret
      ON cr.cr_item_sk = i_ret.i_item_sk
    JOIN tpcds.call_center cc_ret
      ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
    JOIN tpcds.ship_mode sm_ret
      ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    JOIN tpcds.warehouse w_ret
      ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    WHERE d_ret.d_year = 2001
    GROUP BY d_ret.d_year, w_ret.w_warehouse_name
),
web_returns AS (
    SELECT
        d_wr_ret.d_year AS year,
        w_wr.w_warehouse_name AS warehouse,
        SUM(wr.wr_net_loss) AS web_return_loss,
        COUNT(DISTINCT i_wr.i_item_sk) AS web_ret_distinct_items
    FROM tpcds.web_returns wr
    JOIN tpcds.web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.date_dim d_wr_ret
      ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
    JOIN tpcds.time_dim t_wr_ret
      ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
    JOIN tpcds.item i_wr
      ON wr.wr_item_sk = i_wr.i_item_sk
    JOIN tpcds.web_page wp_wr
      ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    JOIN tpcds.warehouse w_wr
      ON ws.ws_warehouse_sk = w_wr.w_warehouse_sk
    WHERE d_wr_ret.d_year = 2001
    GROUP BY d_wr_ret.d_year, w_wr.w_warehouse_name
),
inventory_latest AS (
    SELECT
        d_inv.d_year AS year,
        w_inv.w_warehouse_name AS warehouse,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM tpcds.inventory inv
    JOIN tpcds.date_dim d_inv
      ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN tpcds.warehouse w_inv
      ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    WHERE d_inv.d_year = 2001
    GROUP BY d_inv.d_year, w_inv.w_warehouse_name
)
SELECT
    cs.year,
    cs.warehouse,
    cs.cat_net_profit + ws.web_net_profit - cr.cat_return_loss - wr.web_return_loss AS net_profit_2001,
    cs.cat_qty + ws.web_qty AS total_quantity_sold,
    cs.cat_distinct_items + ws.web_distinct_items AS distinct_items_sold,
    inv.total_on_hand,
    (SELECT SUM(inv2.inv_quantity_on_hand)
       FROM tpcds.inventory inv2
       JOIN tpcds.date_dim d2 ON inv2.inv_date_sk = d2.d_date_sk
       WHERE d2.d_year = 2001) AS total_inventory_all_warehouses
FROM cat_sales cs
JOIN web_sales ws
  ON cs.year = ws.year AND cs.warehouse = ws.warehouse
LEFT JOIN cat_returns cr
  ON cs.year = cr.year AND cs.warehouse = cr.warehouse
LEFT JOIN web_returns wr
  ON cs.year = wr.year AND cs.warehouse = wr.warehouse
LEFT JOIN inventory_latest inv
  ON cs.year = inv.year AND cs.warehouse = inv.warehouse
WHERE cs.cat_net_profit IS NOT NULL
ORDER BY net_profit_2001 DESC
LIMIT 100
