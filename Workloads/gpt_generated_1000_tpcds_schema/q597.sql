WITH
  sampled_ws AS (
    SELECT
      ws_order_number,
      ws_bill_customer_sk,
      ws_ship_customer_sk,
      ws_warehouse_sk,
      ws_web_site_sk,
      ws_net_paid,
      ws_net_paid_inc_ship_tax
    FROM web_sales TABLESAMPLE BERNOULLI (10)
    WHERE ws_warehouse_sk IN (
      SELECT w_warehouse_sk
      FROM warehouse
      WHERE w_county LIKE '%County'
    )
  ),

  ranked_ws AS (
    SELECT
      ws_order_number,
      ws_warehouse_sk,
      ws_net_paid,
      ROW_NUMBER() OVER (PARTITION BY ws_warehouse_sk ORDER BY ws_net_paid DESC) AS rnk
    FROM sampled_ws
  ),

  top_ws AS (
    SELECT ws_order_number, ws_warehouse_sk, ws_net_paid
    FROM ranked_ws
    WHERE rnk <= 5
  ),

  customer_ship AS (
    SELECT
      c_customer_sk,
      c_first_name,
      c_last_name,
      c_birth_country
    FROM customer
    WHERE c_birth_country IN ('SWITZERLAND', 'UKRAINE')
  ),

  customer_bill AS (
    SELECT
      c_customer_sk,
      c_first_name,
      c_last_name,
      c_birth_country
    FROM customer
    WHERE c_birth_country IN ('KOREA', 'TURKMENISTAN')
  ),

  ship_orders AS (
    SELECT
      tw.ws_order_number,
      tw.ws_warehouse_sk,
      tw.ws_net_paid,
      cs.c_birth_country AS ship_birth_country
    FROM top_ws tw
    JOIN sampled_ws sw ON tw.ws_order_number = sw.ws_order_number
    JOIN customer_ship cs ON sw.ws_ship_customer_sk = cs.c_customer_sk
  ),

  bill_orders AS (
    SELECT
      tw.ws_order_number,
      tw.ws_warehouse_sk,
      tw.ws_net_paid,
      cb.c_birth_country AS bill_birth_country
    FROM top_ws tw
    JOIN sampled_ws sw ON tw.ws_order_number = sw.ws_order_number
    JOIN customer_bill cb ON sw.ws_bill_customer_sk = cb.c_customer_sk
  ),

  final_set AS (
    SELECT ws_order_number, ws_warehouse_sk, ws_net_paid, ship_birth_country
    FROM ship_orders
    EXCEPT
    SELECT ws_order_number, ws_warehouse_sk, ws_net_paid, bill_birth_country
    FROM bill_orders
  )
SELECT
  f.ws_order_number,
  f.ws_warehouse_sk,
  f.ws_net_paid,
  f.ship_birth_country,
  (
    SELECT SUM(ws2.ws_net_paid)
    FROM sampled_ws ws2
    WHERE ws2.ws_warehouse_sk = f.ws_warehouse_sk
  ) AS warehouse_total_net_paid
FROM final_set f
JOIN warehouse w ON f.ws_warehouse_sk = w.w_warehouse_sk
ORDER BY f.ws_net_paid DESC, f.ws_order_number
LIMIT 100
