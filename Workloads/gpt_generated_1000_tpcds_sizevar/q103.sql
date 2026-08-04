WITH
  base1 AS (
    SELECT
      w.w_warehouse_name AS w_warehouse_name,
      w.w_state AS w_state,
      p.p_promo_name AS p_promo_name,
      i.i_category AS i_category,
      ca_bill.ca_city AS bill_city,
      ca_ship.ca_city AS ship_city,
      wp.wp_type AS wp_type,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN item i3 ON p.p_item_sk = i3.i_item_sk
    GROUP BY
      w.w_warehouse_name,
      w.w_state,
      p.p_promo_name,
      i.i_category,
      ca_bill.ca_city,
      ca_ship.ca_city,
      wp.wp_type
  ),
  base2 AS (
    SELECT
      w.w_warehouse_name AS w_warehouse_name,
      w.w_state AS w_state,
      p.p_promo_name AS p_promo_name,
      i.i_category AS i_category,
      ca_bill.ca_city AS bill_city,
      ca_ship.ca_city AS ship_city,
      wp.wp_type AS wp_type,
      SUM(ws.ws_ext_sales_price) * 0.9 AS total_sales,
      SUM(ws.ws_net_profit) * 0.9 AS total_profit,
      COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN item i3 ON p.p_item_sk = i3.i_item_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY
      w.w_warehouse_name,
      w.w_state,
      p.p_promo_name,
      i.i_category,
      ca_bill.ca_city,
      ca_ship.ca_city,
      wp.wp_type
  ),
  unioned AS (
    SELECT
      COALESCE(a.w_warehouse_name, b.w_warehouse_name) AS warehouse_name,
      COALESCE(a.w_state, b.w_state) AS state,
      COALESCE(a.p_promo_name, b.p_promo_name) AS promo_name,
      COALESCE(a.i_category, b.i_category) AS category,
      COALESCE(a.bill_city, b.bill_city) AS billing_city,
      COALESCE(a.ship_city, b.ship_city) AS shipping_city,
      COALESCE(a.wp_type, b.wp_type) AS page_type,
      COALESCE(a.total_sales, 0) + COALESCE(b.total_sales, 0) AS combined_sales,
      COALESCE(a.total_profit, 0) + COALESCE(b.total_profit, 0) AS combined_profit,
      COALESCE(a.order_cnt, 0) + COALESCE(b.order_cnt, 0) AS combined_orders
    FROM base1 a
    FULL OUTER JOIN base2 b
      ON a.w_warehouse_name = b.w_warehouse_name
      AND a.w_state = b.w_state
      AND a.p_promo_name = b.p_promo_name
      AND a.i_category = b.i_category
    UNION DISTINCT
    SELECT
      NULL AS warehouse_name,
      NULL AS state,
      NULL AS promo_name,
      NULL AS category,
      NULL AS billing_city,
      NULL AS shipping_city,
      NULL AS page_type,
      0 AS combined_sales,
      0 AS combined_profit,
      0 AS combined_orders
  )
SELECT
  warehouse_name,
  state,
  promo_name,
  category,
  billing_city,
  shipping_city,
  page_type,
  combined_sales,
  combined_profit,
  combined_orders,
  RANK() OVER (PARTITION BY state ORDER BY combined_sales DESC) AS state_sales_rank
FROM unioned
ORDER BY combined_sales DESC
LIMIT 100
