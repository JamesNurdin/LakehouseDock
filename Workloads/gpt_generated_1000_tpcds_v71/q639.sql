WITH catalog_fact AS (
  SELECT
    cs.cs_warehouse_sk,
    cs.cs_sold_time_sk,
    w.w_warehouse_name,
    cp.cp_department,
    t.t_hour,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_sales_price,
    cs.cs_ext_discount_amt,
    cs.cs_net_profit,
    cr.cr_return_quantity,
    cr.cr_net_loss,
    r.r_reason_desc,
    cd_bill.cd_gender,
    hd_bill.hd_vehicle_count
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
  LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cs.cs_quantity > 5
    AND cs.cs_sales_price > 100
    AND w.w_warehouse_sq_ft > 200000
    AND t.t_hour BETWEEN 9 AND 17
    AND cd_bill.cd_gender = 'M'
    AND hd_bill.hd_vehicle_count >= 1
    AND (r.r_reason_desc IS NULL OR r.r_reason_desc LIKE '%not%')
),
web_fact AS (
  SELECT
    ws.ws_warehouse_sk,
    ws.ws_sold_time_sk,
    w.w_warehouse_name,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_ext_discount_amt,
    ws.ws_net_profit,
    wr.wr_return_quantity,
    wr.wr_net_loss,
    r.r_reason_desc,
    cd_bill.cd_gender,
    hd_bill.hd_vehicle_count
  FROM web_sales ws
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
  LEFT JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  WHERE ws.ws_quantity > 5
    AND ws.ws_sales_price > 100
    AND w.w_warehouse_sq_ft > 200000
    AND t.t_hour BETWEEN 9 AND 17
    AND cd_bill.cd_gender = 'M'
    AND hd_bill.hd_vehicle_count >= 1
    AND (r.r_reason_desc IS NULL OR r.r_reason_desc LIKE '%not%')
),
inventory_agg AS (
  SELECT
    inv.inv_warehouse_sk,
    SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
  FROM inventory inv
  GROUP BY inv.inv_warehouse_sk
  HAVING SUM(inv.inv_quantity_on_hand) > 0
)
SELECT
  w.w_warehouse_name,
  COALESCE(cf.cp_department, 'Web') AS channel_department,
  t.t_hour,
  COUNT(DISTINCT COALESCE(cf.cs_order_number, wf.ws_order_number)) AS distinct_orders,
  SUM(COALESCE(cf.cs_net_profit, 0) + COALESCE(wf.ws_net_profit, 0)) AS total_net_profit,
  SUM(COALESCE(cf.cr_net_loss, 0) + COALESCE(wf.wr_net_loss, 0)) AS total_net_loss,
  AVG(COALESCE(cf.cs_ext_discount_amt, wf.ws_ext_discount_amt)) AS avg_discount_amount,
  MAX(COALESCE(cf.cs_sales_price, wf.ws_sales_price)) AS max_sales_price,
  MIN(COALESCE(cf.cs_sales_price, wf.ws_sales_price)) AS min_sales_price,
  SUM(ia.total_qty_on_hand) AS warehouse_inventory_on_hand
FROM (
  SELECT * FROM catalog_fact
) cf
FULL OUTER JOIN (
  SELECT * FROM web_fact
) wf
  ON cf.cs_warehouse_sk = wf.ws_warehouse_sk
 AND cf.cs_sold_time_sk = wf.ws_sold_time_sk
JOIN warehouse w
  ON COALESCE(cf.cs_warehouse_sk, wf.ws_warehouse_sk) = w.w_warehouse_sk
LEFT JOIN time_dim t
  ON COALESCE(cf.cs_sold_time_sk, wf.ws_sold_time_sk) = t.t_time_sk
LEFT JOIN inventory_agg ia
  ON w.w_warehouse_sk = ia.inv_warehouse_sk
GROUP BY
  w.w_warehouse_name,
  COALESCE(cf.cp_department, 'Web'),
  t.t_hour
ORDER BY total_net_profit DESC
LIMIT 100
