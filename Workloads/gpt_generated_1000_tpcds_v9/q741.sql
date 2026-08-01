WITH sales_union AS (
  SELECT
    cs_order_number AS order_number,
    cs_sold_time_sk AS time_sk,
    cs_item_sk AS item_sk,
    cs_warehouse_sk AS warehouse_sk,
    cs_bill_cdemo_sk AS bill_cdemo_sk,
    cs_bill_hdemo_sk AS bill_hdemo_sk,
    cs_ship_cdemo_sk AS ship_cdemo_sk,
    cs_ship_hdemo_sk AS ship_hdemo_sk,
    cs_net_profit AS net_profit,
    cs_ext_sales_price AS ext_sales_price,
    cs_quantity AS quantity,
    cs_promo_sk AS promo_sk,
    'catalog' AS sales_channel
  FROM catalog_sales
  UNION ALL
  SELECT
    ws_order_number AS order_number,
    ws_sold_time_sk AS time_sk,
    ws_item_sk AS item_sk,
    ws_warehouse_sk AS warehouse_sk,
    ws_bill_cdemo_sk AS bill_cdemo_sk,
    ws_bill_hdemo_sk AS bill_hdemo_sk,
    ws_ship_cdemo_sk AS ship_cdemo_sk,
    ws_ship_hdemo_sk AS ship_hdemo_sk,
    ws_net_profit AS net_profit,
    ws_ext_sales_price AS ext_sales_price,
    ws_quantity AS quantity,
    ws_promo_sk AS promo_sk,
    'web' AS sales_channel
  FROM web_sales
),
agg_sales AS (
  SELECT
    i.i_category AS category,
    i.i_brand AS brand,
    w.w_warehouse_name AS warehouse,
    t.t_hour AS hour_of_day,
    SUM(su.ext_sales_price) AS total_sales,
    SUM(su.quantity) AS total_quantity,
    SUM(su.net_profit) AS total_net_profit,
    MAX(inv.inv_quantity_on_hand) AS max_inventory_on_hand,
    (SELECT SUM(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS total_promo_cost,
    i.i_item_sk
  FROM sales_union su
  JOIN time_dim t ON su.time_sk = t.t_time_sk
  JOIN item i ON su.item_sk = i.i_item_sk
  JOIN warehouse w ON su.warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON su.promo_sk = p.p_promo_sk
  LEFT JOIN customer_demographics cd_bill ON su.bill_cdemo_sk = cd_bill.cd_demo_sk
  LEFT JOIN customer_demographics cd_ship ON su.ship_cdemo_sk = cd_ship.cd_demo_sk
  LEFT JOIN household_demographics hd_bill ON su.bill_hdemo_sk = hd_bill.hd_demo_sk
  LEFT JOIN household_demographics hd_ship ON su.ship_hdemo_sk = hd_ship.hd_demo_sk
  CROSS JOIN LATERAL (
    SELECT inv_quantity_on_hand
    FROM inventory
    WHERE inv_item_sk = su.item_sk
      AND inv_warehouse_sk = su.warehouse_sk
    ORDER BY inv_quantity_on_hand DESC
    LIMIT 1
  ) AS inv
  WHERE su.item_sk IN (
    SELECT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 100
  )
  GROUP BY
    i.i_category,
    i.i_brand,
    w.w_warehouse_name,
    t.t_hour,
    i.i_item_sk
)
SELECT
  category,
  brand,
  warehouse,
  hour_of_day,
  total_sales,
  total_quantity,
  total_net_profit,
  max_inventory_on_hand,
  total_promo_cost,
  ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_net_profit DESC) AS category_rank
FROM agg_sales
ORDER BY total_net_profit DESC
LIMIT 100
