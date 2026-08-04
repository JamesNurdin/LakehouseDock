WITH
  sales_base AS (
    SELECT
      cs.cs_item_sk,
      i.i_brand AS item_brand,
      i.i_wholesale_cost,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      w.w_warehouse_name AS cs_warehouse_name,
      w.w_city,
      td.t_meal_time,
      cs.cs_order_number
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE i.i_brand = 'edu packbrand #4'
      AND i.i_wholesale_cost > 2.00
      AND td.t_meal_time = 'dinner'
      AND w.w_city = 'Los Angeles'
      AND cs.cs_net_paid > 1000
      AND cs.cs_quantity >= 2
  ),

  returns_base AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_order_number,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_net_loss
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 50
      AND cr.cr_net_loss > 0
  ),

  intersect_orders AS (
    SELECT cr_order_number FROM returns_base
    INTERSECT
    SELECT cs_order_number FROM sales_base
  ),

  web_base AS (
    SELECT
      ws.ws_item_sk,
      i.i_brand AS item_brand,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_net_profit,
      w.w_warehouse_name AS ws_warehouse_name,
      td.t_meal_time,
      ws.ws_promo_sk,
      ws.ws_order_number
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE i.i_brand = 'edu packbrand #4'
      AND ws.ws_promo_sk IN (1115, 371)
      AND td.t_meal_time = 'dinner'
      AND ws.ws_net_paid > 500
      AND ws.ws_quantity >= 1
  ),

  final_agg AS (
    SELECT
      COALESCE(s.cs_item_sk, wbs.ws_item_sk) AS item_sk,
      COALESCE(s.item_brand, wbs.item_brand) AS brand,
      SUM(CASE WHEN s.cs_net_paid IS NOT NULL THEN s.cs_net_paid ELSE 0 END) AS total_sales_net_paid,
      SUM(CASE WHEN wbs.ws_net_paid IS NOT NULL THEN wbs.ws_net_paid ELSE 0 END) AS total_web_net_paid,
      COUNT(DISTINCT s.cs_order_number) AS cnt_sales_orders,
      COUNT(DISTINCT wbs.ws_order_number) AS cnt_web_orders,
      SUM(r.cr_return_amount) AS total_return_amount,
      AVG(CASE WHEN s.cs_quantity IS NOT NULL THEN s.cs_quantity ELSE wbs.ws_quantity END) AS avg_quantity
    FROM sales_base s
    FULL OUTER JOIN web_base wbs
      ON s.cs_item_sk = wbs.ws_item_sk
     AND s.cs_warehouse_name = wbs.ws_warehouse_name
    LEFT JOIN returns_base r
      ON s.cs_order_number = r.cr_order_number
     OR wbs.ws_order_number = r.cr_order_number
    WHERE s.cs_order_number IN (SELECT cr_order_number FROM intersect_orders)
       OR wbs.ws_order_number IN (SELECT cr_order_number FROM intersect_orders)
    GROUP BY 1,2
  )
SELECT
  item_sk,
  brand,
  total_sales_net_paid,
  total_web_net_paid,
  cnt_sales_orders,
  cnt_web_orders,
  total_return_amount,
  avg_quantity
FROM final_agg
ORDER BY total_sales_net_paid DESC
LIMIT 100
