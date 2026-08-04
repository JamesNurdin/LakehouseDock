WITH
  cr_full AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      i.i_current_price,
      ca.ca_zip AS refund_zip,
      cr.cr_return_quantity,
      cr.cr_returned_date_sk
    FROM catalog_returns cr
    FULL OUTER JOIN item i ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price > 5.00
      AND ca.ca_zip = '79584'
      AND cr.cr_return_quantity >= 1
      AND cr.cr_return_amount > 0
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
  ),
  ws_full AS (
    SELECT
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      ws.ws_ext_ship_cost,
      ws.ws_ext_discount_amt,
      i.i_current_price AS ws_item_price,
      ca.ca_zip AS bill_zip,
      p.p_promo_name,
      p.p_discount_active
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE p.p_discount_active = 'Y'
      AND ca.ca_zip = '10069'
      AND ws.ws_ext_sales_price > 1000
      AND ws.ws_ext_discount_amt > 200
      AND ws.ws_ext_ship_cost < 500
  ),
  intersect_orders AS (
    SELECT cr_order_number AS order_number FROM cr_full
    INTERSECT
    SELECT ws_order_number AS order_number FROM ws_full
  ),
  except_orders AS (
    SELECT cr_order_number AS order_number FROM cr_full
    EXCEPT
    SELECT ws_order_number AS order_number FROM ws_full
  ),
  combined AS (
    SELECT
      COALESCE(cr.cr_order_number, ws.ws_order_number) AS order_number,
      cr.cr_return_amount,
      ws.ws_ext_sales_price,
      cr.i_current_price AS cr_item_price,
      ws.ws_item_price,
      cr.refund_zip,
      ws.bill_zip,
      ws.p_promo_name
    FROM cr_full cr
    FULL OUTER JOIN ws_full ws ON cr.cr_order_number = ws.ws_order_number
    WHERE cr.cr_order_number IN (SELECT order_number FROM intersect_orders)
       OR cr.cr_order_number IN (SELECT order_number FROM except_orders)
       OR ws.ws_order_number IN (SELECT order_number FROM intersect_orders)
       OR ws.ws_order_number IN (SELECT order_number FROM except_orders)
  )
SELECT
  order_number,
  COUNT(*) AS record_cnt,
  SUM(cr_return_amount) AS total_return_amount,
  AVG(ws_ext_sales_price) AS avg_sales_price,
  MIN(COALESCE(cr_item_price, ws_item_price)) AS min_item_price,
  MAX(COALESCE(cr_item_price, ws_item_price)) AS max_item_price
FROM combined
GROUP BY order_number
ORDER BY total_return_amount DESC
LIMIT 100
