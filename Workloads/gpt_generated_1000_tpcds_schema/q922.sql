-- Goal: Analyse combined store return and web sales performance for 2001, focusing on high‑value orders shipped by AIR, filtering by several realistic dimensions, and illustrate set operations (INTERSECT / EXCEPT) on order numbers.
WITH
  -- Base join that pulls together all 12 selected tables
  base AS (
    SELECT
      ws.ws_order_number,
      d_ret.d_year,
      ca_ret.ca_state,
      sm.sm_type,
      SUM(sr.sr_return_amt)               AS total_return_amount,
      SUM(ws.ws_ext_sales_price)           AS total_sales_price,
      AVG(ws.ws_net_profit)                AS avg_net_profit,
      MIN(ws.ws_ship_date_sk)              AS min_ship_date_sk,
      MAX(sr.sr_return_quantity)          AS max_return_qty
    FROM store_returns sr
    JOIN date_dim d_ret
      ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret
      ON sr.sr_return_time_sk = t_ret.t_time_sk
    JOIN household_demographics hd_ret
      ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_address ca_ret
      ON sr.sr_addr_sk = ca_ret.ca_address_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d_ret.d_date_sk
    JOIN time_dim t_sale
      ON ws.ws_sold_time_sk = t_sale.t_time_sk
    JOIN household_demographics hd_bill
      ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
      ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
      ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
      ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN catalog_page cp
      ON cp.cp_start_date_sk = d_wp_creation.d_date_sk
    WHERE d_ret.d_year = 2001                                 -- filter 1
      AND t_ret.t_minute BETWEEN 5 AND 15                     -- filter 2
      AND hd_ret.hd_vehicle_count >= 2                       -- filter 3
      AND ca_ret.ca_state = 'CA'                              -- filter 4
      AND r.r_reason_desc = 'Damaged'                         -- filter 5
      AND sm.sm_code = 'AIR'                                 -- filter 6
      AND ws.ws_list_price > 50                               -- filter 7 (extra)
      AND w.w_state = 'TX'                                    -- filter 8 (extra)
      AND cp.cp_department = 'Electronics'                    -- filter 9 (extra)
    GROUP BY
      ws.ws_order_number,
      d_ret.d_year,
      ca_ret.ca_state,
      sm.sm_type
  ),

  -- Orders with a very high list price
  order_high_price AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_list_price > 120
  ),

  -- Orders that had a large return quantity (store‑return ticket number maps to order number for illustration)
  order_large_return AS (
    SELECT sr_ticket_number AS ws_order_number
    FROM store_returns
    WHERE sr_return_quantity > 30
  ),

  -- Orders sold in the year 2020
  order_2020 AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
  ),

  -- Orders shipped by AIR mode
  order_air_ship AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'AIR'
  ),

  -- Intersection of high‑price and large‑return orders
  intersect_orders AS (
    SELECT ws_order_number FROM order_high_price
    INTERSECT
    SELECT ws_order_number FROM order_large_return
  ),

  -- Orders in 2020 except those shipped by AIR
  except_orders AS (
    SELECT ws_order_number FROM order_2020
    EXCEPT
    SELECT ws_order_number FROM order_air_ship
  )

SELECT DISTINCT
  b.d_year,
  b.ca_state,
  b.sm_type,
  b.total_return_amount,
  b.total_sales_price,
  b.avg_net_profit,
  b.min_ship_date_sk,
  b.max_return_qty
FROM base b
JOIN intersect_orders io
  ON b.ws_order_number = io.ws_order_number
LEFT JOIN except_orders eo
  ON b.ws_order_number = eo.ws_order_number
WHERE eo.ws_order_number IS NULL
LIMIT 100
