WITH base AS (
  SELECT
    d_sales.d_year,
    d_sales.d_quarter_name,
    w.w_warehouse_sk,
    w.w_warehouse_name,
    c.c_customer_sk,
    ws.ws_ext_sales_price,
    sr.sr_return_amt,
    wr.wr_return_amt
  FROM store_returns sr
  JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
  JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
  JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN date_dim d_sales
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
  JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d_wr_return
    ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
  JOIN time_dim t_wr_return
    ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
  WHERE d_sales.d_fy_year = 1905
),
agg AS (
  SELECT
    d_year,
    d_quarter_name,
    w_warehouse_sk,
    w_warehouse_name,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(wr_return_amt) AS total_web_returns,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers
  FROM base
  GROUP BY ROLLUP (d_year, d_quarter_name, w_warehouse_name, w_warehouse_sk)
)
SELECT
  agg.d_year,
  agg.d_quarter_name,
  agg.w_warehouse_name,
  agg.total_sales,
  agg.total_store_returns,
  agg.total_web_returns,
  agg.distinct_customers,
  CASE WHEN agg.total_sales > 0 THEN 'POS' ELSE 'ZERO' END AS sales_status,
  (SELECT SUM(ws2.ws_ext_sales_price)
     FROM web_sales ws2
    WHERE ws2.ws_warehouse_sk = agg.w_warehouse_sk) AS warehouse_lifetime_sales,
  ROW_NUMBER() OVER (PARTITION BY agg.w_warehouse_name ORDER BY agg.total_sales DESC) AS warehouse_sales_rank
FROM agg
ORDER BY agg.total_sales DESC
OFFSET 0
LIMIT 100
