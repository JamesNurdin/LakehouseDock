WITH cs_agg AS (
  SELECT
    cs.cs_item_sk,
    cs.cs_warehouse_sk,
    SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    SUM(CASE WHEN cs.cs_quantity > 5 THEN cs.cs_ext_sales_price ELSE 0 END) AS large_qty_sales,
    MIN(cs.cs_ext_discount_amt) AS min_discount,
    MAX(cs.cs_ext_discount_amt) AS max_discount
  FROM catalog_sales cs
  JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
  JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
  WHERE d_cs.d_year = 2000
    AND t_cs.t_hour BETWEEN 9 AND 17
    AND cs.cs_net_paid_inc_tax > 500
  GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk
),
ws_agg AS (
  SELECT
    ws.ws_item_sk,
    ws.ws_warehouse_sk,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    SUM(ws.ws_ext_tax) AS total_web_tax
  FROM web_sales ws
  JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
  JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
  WHERE d_ws.d_year = 2000
    AND t_ws.t_hour BETWEEN 9 AND 17
  GROUP BY ws.ws_item_sk, ws.ws_warehouse_sk
),
wr_agg AS (
  SELECT
    wr.wr_item_sk,
    SUM(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
  WHERE d_wr.d_year = 2000
  GROUP BY wr.wr_item_sk
),
inv_agg AS (
  SELECT
    inv.inv_item_sk,
    inv.inv_warehouse_sk,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
  FROM inventory inv
  JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
  WHERE d_inv.d_year = 2000
  GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
)
SELECT
  i.i_manufact_id,
  i.i_manufact,
  w.w_warehouse_name,
  SUM(COALESCE(cs_agg.total_catalog_sales, 0)) AS total_catalog_sales,
  SUM(COALESCE(ws_agg.total_web_sales, 0)) AS total_web_sales,
  SUM(COALESCE(wr_agg.total_return_loss, 0)) AS total_return_loss,
  SUM(COALESCE(inv_agg.total_inventory_qty, 0)) AS total_inventory_qty,
  SUM(COALESCE(cs_agg.catalog_order_cnt, 0)) AS catalog_order_cnt,
  SUM(COALESCE(ws_agg.web_order_cnt, 0)) AS web_order_cnt,
  AVG(i.i_current_price) AS avg_item_price,
  MIN(COALESCE(cs_agg.min_discount, 0)) AS min_discount,
  MAX(COALESCE(cs_agg.max_discount, 0)) AS max_discount,
  SUM(COALESCE(cs_agg.large_qty_sales, 0)) AS large_qty_sales,
  SUM(COALESCE(ws_agg.total_web_tax, 0)) AS total_web_tax
FROM cs_agg
JOIN item i ON cs_agg.cs_item_sk = i.i_item_sk
JOIN warehouse w ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ws_agg ON ws_agg.ws_item_sk = i.i_item_sk AND ws_agg.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN wr_agg ON wr_agg.wr_item_sk = i.i_item_sk
LEFT JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.i_manufact_id IN (212, 260)
  AND w.w_state = 'CA'
GROUP BY i.i_manufact_id, i.i_manufact, w.w_warehouse_name
ORDER BY total_catalog_sales DESC
