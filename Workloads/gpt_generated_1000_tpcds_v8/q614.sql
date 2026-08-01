WITH
  sales_agg AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_bill_customer_sk,
      ws.ws_bill_addr_sk,
      ws.ws_web_site_sk,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(*)               AS sales_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12               -- filter on hour of day
      AND i.i_current_price > 10.00               -- filter on price
      AND ws.ws_quantity > 1                     -- filter on quantity
    GROUP BY
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_bill_customer_sk,
      ws.ws_bill_addr_sk,
      ws.ws_web_site_sk
  ),
  returns_agg AS (
    SELECT
      wr.wr_order_number,
      wr.wr_returned_time_sk,
      wr.wr_item_sk,
      SUM(wr.wr_return_amt) AS total_return_amt,
      COUNT(*)               AS return_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12               -- same hour filter as sales
      AND i.i_current_price > 10.00               -- same price filter
      AND wr.wr_return_quantity > 0               -- filter on return qty
    GROUP BY
      wr.wr_order_number,
      wr.wr_returned_time_sk,
      wr.wr_item_sk
  ),
  order_intersect AS (
    SELECT ws_order_number AS order_num
    FROM web_sales ws
    WHERE ws.ws_quantity > 2
    INTERSECT
    SELECT wr_order_number
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
  )
SELECT
  COALESCE(sa.ws_order_number, ra.wr_order_number)               AS order_number,
  wsit.web_name                                                   AS website_name,
  i.i_category                                                    AS item_category,
  t.t_hour                                                        AS hour_of_day,
  sa.total_sales,
  ra.total_return_amt,
  (sa.total_sales - COALESCE(ra.total_return_amt, 0))           AS net_sales,
  sa.sales_cnt,
  ra.return_cnt,
  c.c_first_name,
  c.c_last_name,
  ca.ca_city,
  -- correlated scalar subquery: total refunded amount for the billed customer
  (SELECT COALESCE(SUM(wr2.wr_refunded_cash), 0)
   FROM web_returns wr2
   WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk)        AS cust_total_refunded_cash,
  -- correlated scalar subquery: average return amount for the same item
  (SELECT AVG(wr3.wr_return_amt)
   FROM web_returns wr3
   WHERE wr3.wr_item_sk = i.i_item_sk)                      AS avg_return_per_item
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
  ON sa.ws_order_number = ra.wr_order_number
JOIN web_site wsit
  ON sa.ws_web_site_sk = wsit.web_site_sk
JOIN customer c
  ON sa.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON sa.ws_bill_addr_sk = ca.ca_address_sk
JOIN item i
  ON i.i_item_sk = COALESCE(sa.ws_item_sk, ra.wr_item_sk)
JOIN time_dim t
  ON t.t_time_sk = COALESCE(sa.ws_sold_time_sk, ra.wr_returned_time_sk)
WHERE sa.ws_order_number IN (SELECT order_num FROM order_intersect)
  AND EXISTS (
        SELECT 1
        FROM customer_address ca2
        WHERE ca2.ca_address_sk = sa.ws_bill_addr_sk
          AND ca2.ca_gmt_offset = -8.00
      )
  AND EXISTS (
        SELECT 1
        FROM web_returns wr_exists
        WHERE wr_exists.wr_order_number = sa.ws_order_number
          AND wr_exists.wr_return_amt > 0
      )
ORDER BY net_sales DESC
LIMIT 100
