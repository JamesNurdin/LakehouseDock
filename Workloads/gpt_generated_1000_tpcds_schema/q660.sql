WITH
  high_price_items AS (
    SELECT DISTINCT ws_item_sk
    FROM web_sales
    WHERE ws_sales_price > 120
  ),
  large_inventory_items AS (
    SELECT DISTINCT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 500
  ),
  common_items AS (
    SELECT ws_item_sk AS item_sk
    FROM high_price_items
    INTERSECT
    SELECT inv_item_sk
    FROM large_inventory_items
  ),
  inv_wh_full AS (
    SELECT
      i.inv_item_sk,
      i.inv_quantity_on_hand,
      w.w_warehouse_sk,
      w.w_warehouse_name,
      w.w_state
    FROM inventory i
    FULL OUTER JOIN warehouse w
      ON i.inv_warehouse_sk = w.w_warehouse_sk
  )
SELECT
  w.w_warehouse_name,
  td.t_hour,
  CASE WHEN ws.ws_net_profit > 50 THEN 'High' ELSE 'Low' END AS profit_category,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  AVG(ws.ws_net_profit) AS avg_profit,
  COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM web_sales ws
JOIN time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
JOIN store_sales ss
  ON ss.ss_sold_time_sk = td.t_time_sk
 AND ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN inv_wh_full iwh
  ON w.w_warehouse_sk = iwh.w_warehouse_sk
WHERE ws.ws_item_sk IN (SELECT item_sk FROM common_items)
  AND ws.ws_sales_price > 100
  AND ws.ws_net_profit > 0
  AND td.t_hour BETWEEN 9 AND 17
  AND w.w_state = 'CA'
  AND cd.cd_gender = 'F'
GROUP BY
  w.w_warehouse_name,
  td.t_hour,
  CASE WHEN ws.ws_net_profit > 50 THEN 'High' ELSE 'Low' END
ORDER BY total_sales DESC
