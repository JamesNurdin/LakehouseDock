WITH merged_sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_bill_customer_sk,
    cs.cs_ship_customer_sk,
    cs.cs_item_sk,
    cs.cs_ship_mode_sk,
    cs.cs_warehouse_sk,
    cs.cs_net_profit,
    cs.cs_ext_sales_price,
    ws.ws_bill_customer_sk,
    ws.ws_ship_customer_sk,
    ws.ws_item_sk AS ws_item_sk,
    ws.ws_ship_mode_sk AS ws_ship_mode_sk,
    ws.ws_warehouse_sk AS ws_warehouse_sk,
    ws.ws_net_profit,
    ws.ws_ext_sales_price
  FROM catalog_sales cs
  INNER JOIN web_sales ws
    ON cs.cs_order_number = ws.ws_order_number
    AND cs.cs_item_sk = ws.ws_item_sk
)
SELECT
  s.rn,
  s.cs_order_number,
  c_bill.c_customer_id        AS bill_customer_id,
  c_ship.c_customer_id        AS ship_customer_id,
  i_cs.i_product_name         AS catalog_item_name,
  i_ws.i_product_name         AS web_item_name,
  sm_cs.sm_type               AS catalog_ship_type,
  sm_ws.sm_type               AS web_ship_type,
  w_cs.w_warehouse_name       AS catalog_warehouse,
  w_ws.w_warehouse_name       AS web_warehouse,
  s.cs_net_profit             AS catalog_net_profit,
  s.ws_net_profit             AS web_net_profit,
  s.cnt_distinct_customers,
  s.sum_distinct_ext_sales_price
FROM (
  SELECT
    merged_sales.*, 
    ROW_NUMBER() OVER (ORDER BY merged_sales.cs_net_profit DESC) AS rn,
    COUNT(DISTINCT merged_sales.cs_bill_customer_sk) OVER ()    AS cnt_distinct_customers,
    SUM(DISTINCT merged_sales.cs_ext_sales_price) OVER ()       AS sum_distinct_ext_sales_price
  FROM merged_sales
  WHERE merged_sales.cs_net_profit > (
          SELECT AVG(ws_net_profit) FROM web_sales
        )
    AND merged_sales.cs_item_sk IN (
          SELECT i_item_sk FROM item WHERE i_color = 'Red'
        )
) s
JOIN customer c_bill   ON s.cs_bill_customer_sk   = c_bill.c_customer_sk
JOIN customer c_ship   ON s.cs_ship_customer_sk   = c_ship.c_customer_sk
JOIN customer c_ws_bill ON s.ws_bill_customer_sk  = c_ws_bill.c_customer_sk
JOIN customer c_ws_ship ON s.ws_ship_customer_sk  = c_ws_ship.c_customer_sk
JOIN item i_cs        ON s.cs_item_sk           = i_cs.i_item_sk
JOIN item i_ws        ON s.ws_item_sk           = i_ws.i_item_sk
JOIN ship_mode sm_cs   ON s.cs_ship_mode_sk      = sm_cs.sm_ship_mode_sk
JOIN ship_mode sm_ws   ON s.ws_ship_mode_sk      = sm_ws.sm_ship_mode_sk
JOIN warehouse w_cs    ON s.cs_warehouse_sk      = w_cs.w_warehouse_sk
JOIN warehouse w_ws    ON s.ws_warehouse_sk      = w_ws.w_warehouse_sk
WHERE c_bill.c_preferred_cust_flag = 'Y'
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number IN (
                SELECT cs_order_number FROM catalog_sales
                EXCEPT
                SELECT ws_order_number FROM web_sales
              )
          AND cs2.cs_bill_customer_sk = c_bill.c_customer_sk
      )
ORDER BY s.cs_net_profit DESC
LIMIT 100
