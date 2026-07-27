WITH
  distinct_customers AS (
    SELECT DISTINCT ca_address_sk
    FROM customer_address
    WHERE ca_location_type = 'condo'
  ),
  ss_agg AS (
    SELECT
      ss_item_sk,
      ss_store_sk,
      ss_hdemo_sk,
      ss_addr_sk,
      SUM(ss_ext_sales_price) AS store_sales_total,
      SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_sk, ss_store_sk, ss_hdemo_sk, ss_addr_sk
  )
SELECT
  i.i_category,
  s.s_store_name,
  hd_ss.hd_vehicle_count,
  ca_ss.ca_state,
  ss_agg.store_sales_total,
  SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
  SUM(wr.wr_return_amt) AS total_return_amount,
  ib_bill.ib_lower_bound AS bill_income_lower,
  ib_return.ib_upper_bound AS return_income_upper,
  ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss_agg.store_sales_total DESC) AS category_store_rank
FROM ss_agg
JOIN item i
  ON ss_agg.ss_item_sk = i.i_item_sk
JOIN store s
  ON ss_agg.ss_store_sk = s.s_store_sk
JOIN household_demographics hd_ss
  ON ss_agg.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss
  ON ss_agg.ss_addr_sk = ca_ss.ca_address_sk
JOIN distinct_customers dc
  ON ca_ss.ca_address_sk = dc.ca_address_sk
LEFT JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN income_band ib_bill
  ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN household_demographics hd_return
  ON wr.wr_refunded_hdemo_sk = hd_return.hd_demo_sk
LEFT JOIN income_band ib_return
  ON hd_return.hd_income_band_sk = ib_return.ib_income_band_sk
LEFT JOIN customer_address ca_return
  ON wr.wr_refunded_addr_sk = ca_return.ca_address_sk
WHERE i.i_rec_end_date = DATE '2000-10-26'
GROUP BY
  i.i_category,
  s.s_store_name,
  hd_ss.hd_vehicle_count,
  ca_ss.ca_state,
  ss_agg.store_sales_total,
  ib_bill.ib_lower_bound,
  ib_return.ib_upper_bound
ORDER BY
  ss_agg.store_sales_total DESC,
  i.i_category
LIMIT 100
