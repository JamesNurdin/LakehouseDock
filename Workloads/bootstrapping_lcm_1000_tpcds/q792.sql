SELECT
  d_sales.d_year AS sales_year,
  d_sales.d_quarter_seq AS sales_quarter,
  s.s_store_name,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cr.cr_net_loss) AS total_net_loss,
  COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
  AVG(hd_refunded.hd_income_band_sk) AS avg_refunded_income_band,
  AVG(hd_bill.hd_income_band_sk) AS avg_bill_income_band,
  SUM(cs.cs_ext_discount_amt) AS total_discount,
  SUM(cr.cr_fee) AS total_fee,
  SUM(cs.cs_ext_wholesale_cost) AS total_wholesale_cost
FROM catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_sales
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_return.d_date_sk
JOIN household_demographics hd_refunded
  ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
  ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
GROUP BY
  d_sales.d_year,
  d_sales.d_quarter_seq,
  s.s_store_name
ORDER BY total_net_loss DESC
LIMIT 100
