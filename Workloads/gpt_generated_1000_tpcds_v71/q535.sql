WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_paid               AS cs_net_paid,
    cr.cr_return_amount          AS cr_return_amount,
    ws.ws_net_paid               AS ws_net_paid,
    wr.wr_return_amt             AS wr_return_amt,
    i.i_category                 AS i_category,
    d_sold.d_year                AS sold_year,
    d_ship.d_year                AS ship_year,
    d_ret.d_year                 AS return_year,
    d_ws_sold.d_year             AS ws_sold_year,
    d_ws_ship.d_year             AS ws_ship_year,
    s.s_store_name               AS store_name,
    p.p_promo_name               AS promo_name,
    cust_bill.c_customer_id      AS bill_cust_id,
    cust_ship.c_customer_id      AS ship_cust_id,
    cust_ref.c_customer_id       AS refunded_cust_id,
    ws_cust.c_customer_id        AS ws_bill_cust_id,
    wr_cust.c_customer_id        AS wr_refunded_cust_id,
    w.w_warehouse_name           AS warehouse_name,
    hd_bill.hd_income_band_sk    AS bill_income_band,
    hd_ship.hd_income_band_sk    AS ship_income_band,
    hd_ref.hd_income_band_sk     AS refunded_income_band,
    hd_ws.hd_income_band_sk      AS ws_income_band,
    hd_wr.hd_income_band_sk      AS wr_income_band
  FROM catalog_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN customer cust_bill
    ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
  JOIN customer cust_ship
    ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
  JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  LEFT JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
  LEFT JOIN customer cust_ref
    ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
  LEFT JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  LEFT JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
  LEFT JOIN customer ws_cust
    ON ws.ws_bill_customer_sk = ws_cust.c_customer_sk
  LEFT JOIN household_demographics hd_ws
    ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
  LEFT JOIN customer wr_cust
    ON wr.wr_refunded_customer_sk = wr_cust.c_customer_sk
  LEFT JOIN household_demographics hd_wr
    ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
  LEFT JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
)
SELECT
  i_category,
  sold_year,
  SUM(cs_net_paid)          AS total_catalog_sales,
  SUM(cr_return_amount)     AS total_catalog_returns,
  SUM(ws_net_paid)          AS total_web_sales,
  SUM(wr_return_amt)        AS total_web_returns,
  COUNT(DISTINCT cs_order_number) AS num_orders,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY sold_year DESC) AS rn_category_year
FROM base
GROUP BY ROLLUP (i_category, sold_year)
ORDER BY i_category ASC NULLS FIRST, sold_year DESC NULLS LAST
LIMIT 100
