/*
  Goal: Identify web order numbers that (1) belong to a high‑value brand and have a positive profit status, (2) also match a specific formulation pattern, while (3) excluding small‑quantity orders. The query demonstrates intersecting two key sets, subtracting a third set, uses a CASE expression for profit labeling, and includes EXISTS subqueries for additional filtering.
*/
WITH
  sub1 AS (
    SELECT DISTINCT
      ws.ws_order_number,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_brand_id = 1001001                -- example brand id from sample data
      AND ws.ws_ext_ship_cost > 100            -- ship cost filter using realistic values
      AND EXISTS (
        SELECT 1
        FROM item i2
        WHERE i2.i_item_sk = ws.ws_item_sk
          AND i2.i_color = 'ivory'            -- example colour predicate
      )
  ),
  sub2 AS (
    SELECT DISTINCT
      ws.ws_order_number,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_formulation LIKE '%sky%'        -- matches values like "968467777sky92069287"
      AND ws.ws_ext_ship_cost > 150
      AND EXISTS (
        SELECT 1
        FROM item i2
        WHERE i2.i_item_sk = ws.ws_item_sk
          AND i2.i_color = 'ivory'
      )
  ),
  sub3 AS (
    SELECT DISTINCT
      ws.ws_order_number,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_quantity < 5                 -- small‑quantity orders to be excluded
  ),
  intersect_set AS (
    SELECT ws_order_number, profit_status FROM sub1
    INTERSECT
    SELECT ws_order_number, profit_status FROM sub2
  ),
  final_set AS (
    SELECT ws_order_number, profit_status FROM intersect_set
    EXCEPT
    SELECT ws_order_number, profit_status FROM sub3
  )
SELECT
  ws_order_number,
  profit_status
FROM final_set
ORDER BY ws_order_number DESC
LIMIT 100
