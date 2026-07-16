WITH sales_union AS (
  SELECT
    ss.ss_item_sk AS item_sk,
    ss.ss_quantity AS quantity,
    ss.ss_ext_sales_price AS ext_sales_price,
    ss.ss_net_profit AS net_profit,
    ss.ss_ext_discount_amt AS discount_amt,
    ss.ss_addr_sk AS addr_sk,
    CAST(NULL AS integer) AS ship_mode_sk,
    CAST(NULL AS integer) AS warehouse_sk,
    ss.ss_sold_date_sk AS sold_date_sk
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
    AND ss.ss_quantity > 0
  UNION ALL
  SELECT
    ws.ws_item_sk AS item_sk,
    ws.ws_quantity AS quantity,
    ws.ws_ext_sales_price AS ext_sales_price,
    ws.ws_net_profit AS net_profit,
    ws.ws_ext_discount_amt AS discount_amt,
    ws.ws_ship_addr_sk AS addr_sk,
    ws.ws_ship_mode_sk AS ship_mode_sk,
    ws.ws_warehouse_sk AS warehouse_sk,
    ws.ws_sold_date_sk AS sold_date_sk
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    AND ws.ws_quantity > 0
)
SELECT
  i.i_category,
  i.i_brand,
  ca.ca_state AS region_state,
  COALESCE(sm.sm_type, 'In-Store') AS shipping_mode,
  SUM(su.ext_sales_price) AS total_sales,
  SUM(su.net_profit) AS total_profit,
  SUM(su.quantity) AS total_quantity,
  AVG(su.discount_amt) AS avg_discount,
  COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_on_hand,
  SUM(su.net_profit) / NULLIF(SUM(su.ext_sales_price), 0) AS profit_margin
FROM sales_union su
JOIN item i
  ON su.item_sk = i.i_item_sk
JOIN customer_address ca
  ON su.addr_sk = ca.ca_address_sk
LEFT JOIN ship_mode sm
  ON su.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
  ON su.warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory inv
  ON i.i_item_sk = inv.inv_item_sk
     AND inv.inv_warehouse_sk = su.warehouse_sk
WHERE ca.ca_state IN ('CA', 'TX', 'NY')
  AND ca.ca_location_type = 'single family'
  AND i.i_category IN ('Electronics', 'Furniture')
GROUP BY
  i.i_category,
  i.i_brand,
  ca.ca_state,
  COALESCE(sm.sm_type, 'In-Store')
HAVING SUM(su.ext_sales_price) > 10000
ORDER BY profit_margin DESC
LIMIT 20
