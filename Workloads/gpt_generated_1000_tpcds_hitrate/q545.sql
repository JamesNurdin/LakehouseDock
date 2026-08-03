WITH sales_2000 AS (
  SELECT
    COALESCE(ws.ws_order_number, wr.wr_order_number) AS order_number,
    COALESCE(ws.ws_item_sk, wr.wr_item_sk) AS item_sk,
    ws.ws_warehouse_sk AS warehouse_sk,
    d.d_year AS year,
    ws.ws_ext_sales_price AS sales_price,
    CASE WHEN ws.ws_ext_sales_price > 0 THEN 'Positive' ELSE 'NonPositive' END AS profit_flag,
    (
      SELECT SUM(inv.inv_quantity_on_hand)
      FROM inventory inv
      WHERE inv.inv_item_sk = COALESCE(ws.ws_item_sk, wr.wr_item_sk)
        AND inv.inv_date_sk = COALESCE(ws.ws_sold_date_sk, wr.wr_returned_date_sk)
    ) AS total_inventory,
    CASE WHEN EXISTS (
           SELECT 1 FROM promotion p
           WHERE p.p_item_sk = COALESCE(ws.ws_item_sk, wr.wr_item_sk)
             AND p.p_start_date_sk <= COALESCE(ws.ws_sold_date_sk, wr.wr_returned_date_sk)
             AND p.p_end_date_sk   >= COALESCE(ws.ws_sold_date_sk, wr.wr_returned_date_sk)
         ) THEN 1 ELSE 0 END AS promo_active,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_warehouse_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn
  FROM web_sales ws
  FULL OUTER JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk       = wr.wr_item_sk
  JOIN date_dim d
    ON COALESCE(ws.ws_sold_date_sk, wr.wr_returned_date_sk) = d.d_date_sk
  WHERE d.d_year = 2000
),

sales_2001 AS (
  SELECT
    COALESCE(ws.ws_order_number, wr.wr_order_number) AS order_number,
    COALESCE(ws.ws_item_sk, wr.wr_item_sk) AS item_sk,
    ws.ws_warehouse_sk AS warehouse_sk,
    d.d_year AS year,
    ws.ws_ext_sales_price AS sales_price,
    CASE WHEN ws.ws_ext_sales_price > 0 THEN 'Positive' ELSE 'NonPositive' END AS profit_flag,
    (
      SELECT SUM(inv.inv_quantity_on_hand)
      FROM inventory inv
      WHERE inv.inv_item_sk = COALESCE(ws.ws_item_sk, wr.wr_item_sk)
        AND inv.inv_date_sk = COALESCE(ws.ws_sold_date_sk, wr.wr_returned_date_sk)
    ) AS total_inventory,
    CASE WHEN EXISTS (
           SELECT 1 FROM promotion p
           WHERE p.p_item_sk = COALESCE(ws.ws_item_sk, wr.wr_item_sk)
             AND p.p_start_date_sk <= COALESCE(ws.ws_sold_date_sk, wr.wr_returned_date_sk)
             AND p.p_end_date_sk   >= COALESCE(ws.ws_sold_date_sk, wr.wr_returned_date_sk)
         ) THEN 1 ELSE 0 END AS promo_active,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_warehouse_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn
  FROM web_sales ws
  FULL OUTER JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk       = wr.wr_item_sk
  JOIN date_dim d
    ON COALESCE(ws.ws_sold_date_sk, wr.wr_returned_date_sk) = d.d_date_sk
  WHERE d.d_year = 2001
),

combined AS (
  SELECT * FROM sales_2000
  UNION ALL
  SELECT * FROM sales_2001
)
SELECT
  order_number,
  item_sk,
  warehouse_sk,
  year,
  sales_price,
  profit_flag,
  total_inventory,
  promo_active
FROM combined
WHERE rn <= 5
ORDER BY year, warehouse_sk, sales_price DESC
LIMIT 100
