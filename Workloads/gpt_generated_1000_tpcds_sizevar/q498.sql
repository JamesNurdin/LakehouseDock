WITH
  base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_profit,
      cp.cp_department,
      ca_bill.ca_state,
      ca_bill.ca_country,
      ws.ws_order_number AS ws_order,
      wp.wp_type,
      sr.sr_return_quantity AS store_ret_qty,
      wr.wr_return_quantity AS web_ret_qty
    FROM tpcds.catalog_sales cs
    RIGHT OUTER JOIN tpcds.catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN tpcds.customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN tpcds.customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN tpcds.catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN tpcds.customer_address ca_refund
      ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    LEFT JOIN tpcds.customer_address ca_returning
      ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    LEFT JOIN tpcds.web_sales ws
      ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN tpcds.web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN tpcds.store_returns sr
      ON sr.sr_addr_sk = ca_ship.ca_address_sk
  ),
  return_orders AS (
    SELECT cr_order_number AS order_num FROM tpcds.catalog_returns
    UNION
    SELECT wr_order_number FROM tpcds.web_returns
  ),
  orders_without_returns AS (
    SELECT DISTINCT cs_order_number FROM base
    EXCEPT
    SELECT order_num FROM return_orders
  )
SELECT
  dept,
  state,
  COUNT(*) AS total_orders,
  SUM(net_profit) AS total_profit,
  SUM(CASE WHEN cs_order_number IN (SELECT cs_order_number FROM orders_without_returns) THEN 1 ELSE 0 END) AS orders_without_any_return
FROM (
  SELECT
    b.cs_order_number,
    b.cp_department AS dept,
    b.ca_state AS state,
    b.cs_net_profit AS net_profit,
    t.region
  FROM base b
  CROSS JOIN UNNEST(ARRAY[b.ca_state, b.ca_country]) AS t(region)
) q
GROUP BY dept, state
ORDER BY total_profit DESC
OFFSET 0 FETCH NEXT 10 ROWS ONLY
