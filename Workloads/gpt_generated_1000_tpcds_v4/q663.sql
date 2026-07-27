WITH base AS (
  SELECT
    s.s_store_name AS store_name,
    i.i_category AS i_category,
    d_return.d_year AS return_year,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    COUNT(DISTINCT ws.ws_order_number) AS num_sales
  FROM store_returns sr
  JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
  JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  JOIN customer c_return
    ON sr.sr_customer_sk = c_return.c_customer_sk
  JOIN customer_address ca_return
    ON sr.sr_addr_sk = ca_return.ca_address_sk
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  WHERE d_return.d_year = 2001
    AND i.i_units = 'Each'
  GROUP BY
    s.s_store_name,
    i.i_category,
    d_return.d_year
)
SELECT
  store_name,
  i_category,
  return_year,
  total_return_amount,
  total_sales_amount,
  num_returns,
  num_sales,
  ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY total_return_amount DESC) AS return_rank_by_store
FROM base
ORDER BY total_return_amount DESC
LIMIT 100
