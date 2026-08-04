WITH
  cs AS (
    SELECT
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cs.cs_sold_date_sk,
      cs.cs_warehouse_sk,
      cs.cs_catalog_page_sk,
      cs.cs_call_center_sk,
      cs.cs_bill_cdemo_sk
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_quantity > 0
  ),
  ws AS (
    SELECT
      ws.ws_order_number,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      ws.ws_sold_date_sk,
      ws.ws_warehouse_sk,
      ws.ws_web_page_sk,
      ws.ws_bill_cdemo_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_quantity > 0
  ),
  inv AS (
    SELECT
      i.inv_warehouse_sk,
      i.inv_date_sk,
      SUM(i.inv_quantity_on_hand) AS total_qty_on_hand
    FROM tpcds.inventory i
    GROUP BY i.inv_warehouse_sk, i.inv_date_sk
  )
SELECT
  d.d_year,
  w.w_state,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
  COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
  SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
  SUM(ws.ws_ext_sales_price) AS web_sales_total,
  SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
  AVG(inv.total_qty_on_hand) AS avg_inventory_on_hand,
  COUNT(DISTINCT s.s_store_sk) AS store_cnt,
  MIN(cd.cd_purchase_estimate) AS min_purchase_estimate,
  MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
FROM cs
JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
  AND inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 1914
  AND w.w_state = 'CA'
  AND cd.cd_marital_status = 'M'
GROUP BY d.d_year, w.w_state
ORDER BY d.d_year DESC, w.w_state
LIMIT 100
