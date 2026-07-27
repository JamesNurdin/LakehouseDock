WITH
  ws AS (
    SELECT *
    FROM web_sales
  ),
  cc AS (
    SELECT *
    FROM call_center
  ),
  cp AS (
    SELECT *
    FROM catalog_page
  ),
  c_bill AS (
    SELECT *
    FROM customer
  ),
  c_ship AS (
    SELECT *
    FROM customer
  ),
  hd_bill AS (
    SELECT *
    FROM household_demographics
  ),
  hd_ship AS (
    SELECT *
    FROM household_demographics
  ),
  ib AS (
    SELECT *
    FROM income_band
  ),
  it AS (
    SELECT *
    FROM item
  ),
  sr AS (
    SELECT *
    FROM store_returns
  ),
  wr AS (
    SELECT *
    FROM web_returns
  ),
  d_sold AS (
    SELECT *
    FROM date_dim
  ),
  d_ship AS (
    SELECT *
    FROM date_dim
  )
SELECT
  d_sold.d_year AS sold_year,
  it.i_category,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns,
  SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_returns,
  SUM(ws.ws_net_profit) AS total_profit,
  CASE
    WHEN SUM(ws.ws_net_profit) > 1000000 THEN 'HIGH'
    ELSE 'NORMAL'
  END AS profit_flag
FROM ws
JOIN d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN it
  ON ws.ws_item_sk = it.i_item_sk
JOIN c_bill
  ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN c_ship
  ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN sr
  ON sr.sr_item_sk = ws.ws_item_sk
     AND sr.sr_customer_sk = ws.ws_bill_customer_sk
     AND sr.sr_hdemo_sk = ws.ws_bill_hdemo_sk
     AND sr.sr_returned_date_sk = d_sold.d_date_sk
JOIN cc
  ON cc.cc_open_date_sk = d_ship.d_date_sk
JOIN cp
  ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2002
GROUP BY d_sold.d_year, it.i_category
ORDER BY total_sales DESC
LIMIT 100
