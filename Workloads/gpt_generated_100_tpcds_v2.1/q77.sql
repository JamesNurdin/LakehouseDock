WITH base AS (
  SELECT
    d.d_year,
    w.w_warehouse_id,
    w.w_warehouse_sk,
    cc.cc_name,
    ss.ss_ext_list_price,
    inv.inv_quantity_on_hand,
    hd.hd_vehicle_count,
    cs.cs_net_paid,
    ws.ws_net_paid,
    ss.ss_net_paid,
    cr.cr_net_loss,
    wr.wr_net_loss,
    cs.cs_order_number,
    ws.ws_order_number
  FROM date_dim d
  INNER JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  INNER JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  INNER JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                               AND cr.cr_order_number = cs.cs_order_number
  INNER JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                           AND ws.ws_warehouse_sk = w.w_warehouse_sk
  INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  INNER JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                             AND wr.wr_order_number = ws.ws_order_number
  INNER JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                           AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2000
    AND w.w_warehouse_id = 'AAAAAAAAMAAAAAAA'
    AND cc.cc_state = 'CA'
    AND ss.ss_ext_list_price > 1000.00
    AND inv.inv_quantity_on_hand > 0
    AND hd.hd_vehicle_count >= 2
)
SELECT
  w_warehouse_id,
  d_year,
  cc_name,
  SUM(cs_net_paid) AS total_catalog_net_paid,
  SUM(ws_net_paid) AS total_web_net_paid,
  SUM(ss_net_paid) AS total_store_net_paid,
  SUM(cr_net_loss) AS total_catalog_returns_loss,
  SUM(wr_net_loss) AS total_web_returns_loss,
  COUNT(DISTINCT cs_order_number) AS catalog_orders,
  COUNT(DISTINCT ws_order_number) AS web_orders,
  (SUM(cs_net_paid) + SUM(ws_net_paid) + SUM(ss_net_paid)) AS total_sales,
  (SELECT AVG(cs2.cs_net_paid)
     FROM catalog_sales cs2
    WHERE cs2.cs_warehouse_sk = w_warehouse_sk) AS avg_catalog_net_paid_per_warehouse
FROM base
GROUP BY w_warehouse_id, w_warehouse_sk, d_year, cc_name
HAVING SUM(cs_net_paid) > 50000
ORDER BY total_sales DESC
LIMIT 100
