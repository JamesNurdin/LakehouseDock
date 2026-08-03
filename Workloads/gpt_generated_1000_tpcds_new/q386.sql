-- goal: identify high‑value orders from web and store channels in 2021, exclude web orders that were later returned, combine the two sources, add a row number, and show the average store net paid for the same year
WITH
  -- all web orders in 2021 with a categorised amount
  web_orders AS (
    SELECT
      ws.ws_order_number                     AS order_number,
      ws.ws_bill_customer_sk                AS customer_sk,
      ws.ws_net_paid                        AS net_paid,
      d.d_year                              AS year,
      CASE WHEN ws.ws_net_paid > 500 THEN 'High' ELSE 'Low' END AS amount_category
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
  ),
  -- all web returns in 2021 (just the order numbers)
  web_returns_set AS (
    SELECT
      wr.wr_order_number AS order_number
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
  ),
  -- keys of web orders that were NOT returned (EXCEPT implements the subtraction)
  web_orders_not_returned_keys AS (
    SELECT order_number
    FROM (
      SELECT ws.ws_order_number AS order_number
      FROM tpcds.web_sales ws
      JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
      WHERE d.d_year = 2021
    )
    EXCEPT
    SELECT order_number FROM web_returns_set
  ),
  -- full detail of the non‑returned web orders
  web_orders_not_returned AS (
    SELECT
      o.order_number,
      o.customer_sk,
      o.net_paid,
      o.year,
      o.amount_category
    FROM web_orders o
    JOIN web_orders_not_returned_keys k
      ON o.order_number = k.order_number
  ),
  -- store orders in 2021 with the same categorisation
  store_orders AS (
    SELECT
      ss.ss_ticket_number                    AS order_number,
      ss.ss_customer_sk                      AS customer_sk,
      ss.ss_net_paid                         AS net_paid,
      d.d_year                               AS year,
      CASE WHEN ss.ss_net_paid > 500 THEN 'High' ELSE 'Low' END AS amount_category
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
  ),
  -- combine both channels (UNION ALL keeps duplicates as they represent different channels)
  combined_orders AS (
    SELECT * FROM web_orders_not_returned
    UNION ALL
    SELECT * FROM store_orders
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY co.year DESC, co.net_paid DESC) AS row_num,
  co.order_number,
  co.customer_sk,
  co.net_paid,
  co.year,
  co.amount_category,
  -- scalar subquery: average store net paid for the same year
  (SELECT AVG(ss2.ss_net_paid)
   FROM tpcds.store_sales ss2
   JOIN tpcds.date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
   WHERE d2.d_year = co.year) AS avg_store_net_paid_year
FROM combined_orders co
ORDER BY co.year DESC, co.net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
