WITH
  -- Bill‑side customers with distinct aggregates
  bill_customers AS (
    SELECT
      ws.ws_bill_customer_sk AS cust_sk,
      SUM(DISTINCT ws.ws_ext_sales_price) AS total_sales_distinct,
      COUNT(DISTINCT ws.ws_order_number)      AS distinct_orders
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 1000
    GROUP BY ws.ws_bill_customer_sk
  ),

  -- Ship‑side customers with distinct aggregates
  ship_customers AS (
    SELECT
      ws.ws_ship_customer_sk AS cust_sk,
      COUNT(DISTINCT ws.ws_item_sk)      AS distinct_items,
      SUM(DISTINCT ws.ws_ext_wholesale_cost) AS sum_dist_wholesale
    FROM web_sales ws
    WHERE ws.ws_ext_wholesale_cost < 3000
    GROUP BY ws.ws_ship_customer_sk
  ),

  -- Customers appearing in BOTH bill and ship sets
  intersect_customers AS (
    SELECT cust_sk FROM bill_customers
    INTERSECT
    SELECT cust_sk FROM ship_customers
  ),

  -- Keep all warehouses even if they have no sales (RIGHT OUTER JOIN)
  right_warehouses AS (
    SELECT
      w.w_warehouse_sk,
      w.w_city,
      COALESCE(SUM(ws.ws_ext_sales_price), 0) AS warehouse_sales
    FROM warehouse w
    RIGHT OUTER JOIN web_sales ws
      ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_city
  ),

  -- Union of two gender‑based aggregations (deduped by UNION)
  union_agg AS (
    SELECT
      c.c_customer_id,
      cd.cd_gender,
      COUNT(DISTINCT ws.ws_order_number) AS orders_by_gender
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_id, cd.cd_gender

    UNION

    SELECT
      c.c_customer_id,
      cd.cd_gender,
      COUNT(DISTINCT ws.ws_order_number) AS orders_by_gender
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'S'
    GROUP BY c.c_customer_id, cd.cd_gender
  ),

  -- Customers that bill but never ship (EXCEPT)
  except_customers AS (
    SELECT cust_sk FROM bill_customers
    EXCEPT
    SELECT cust_sk FROM ship_customers
  ),

  -- Anti‑join: customers with no high‑discount sales (NOT EXISTS)
  anti_join_customers AS (
    SELECT c.c_customer_id
    FROM customer c
    WHERE NOT EXISTS (
      SELECT 1
      FROM web_sales ws
      WHERE ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_ext_discount_amt > 500
    )
  )

SELECT
  ic.cust_sk,
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  bc.total_sales_distinct,
  bc.distinct_orders,
  sc.distinct_items,
  sc.sum_dist_wholesale,
  rw.w_city,
  rw.warehouse_sales,
  ua.cd_gender,
  ua.orders_by_gender,
  ec.cust_sk    AS except_cust_sk,
  anc.c_customer_id AS anti_cust_id
FROM intersect_customers ic
JOIN customer c ON c.c_customer_sk = ic.cust_sk
LEFT JOIN bill_customers bc ON bc.cust_sk = ic.cust_sk
LEFT JOIN ship_customers sc ON sc.cust_sk = ic.cust_sk
LEFT JOIN right_warehouses rw ON rw.w_warehouse_sk = ic.cust_sk
LEFT JOIN union_agg ua ON ua.c_customer_id = c.c_customer_id
LEFT JOIN except_customers ec ON ec.cust_sk = ic.cust_sk
LEFT JOIN anti_join_customers anc ON anc.c_customer_id = c.c_customer_id
ORDER BY ic.cust_sk
LIMIT 100
