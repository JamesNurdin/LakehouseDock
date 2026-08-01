WITH inv_sample AS (
  SELECT inv_warehouse_sk, inv_item_sk, inv_quantity_on_hand
  FROM inventory
  TABLESAMPLE BERNOULLI (10)  -- sample 10% of rows
),
warehouse_with_inventory AS (
  SELECT w.w_warehouse_sk,
         w.w_warehouse_name,
         i.inv_item_sk,
         i.inv_quantity_on_hand,
         inv_sum.total_qty
  FROM warehouse w
  JOIN inv_sample i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN LATERAL (
    SELECT SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory inv
    WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
  ) inv_sum ON TRUE
  WHERE w.w_warehouse_sq_ft > 600000
),
warehouse_with_sales AS (
  SELECT w.w_warehouse_sk,
         w.w_warehouse_name,
         ws.ws_item_sk,
         ws.ws_ext_sales_price,
         ws.ws_net_profit
  FROM warehouse w
  JOIN web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450900 AND 2451000
    AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
          AND ws2.ws_ext_sales_price > 500
    )
)
SELECT DISTINCT w_warehouse_sk, w_warehouse_name
FROM (
   SELECT w_warehouse_sk, w_warehouse_name
   FROM warehouse_with_inventory
   WHERE inv_quantity_on_hand > 500

   UNION

   SELECT w_warehouse_sk, w_warehouse_name
   FROM warehouse_with_sales
   WHERE ws_ext_sales_price > 1000
) AS combined
EXCEPT
SELECT w_warehouse_sk, w_warehouse_name
FROM warehouse_with_sales
WHERE ws_ext_sales_price < 200
LIMIT 100
