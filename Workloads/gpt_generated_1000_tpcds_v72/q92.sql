WITH sales_data AS (
  SELECT
    i.i_category,
    s.s_state,
    d_sold.d_year,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(*) AS sales_cnt,
    AVG(cs.cs_sales_price) AS avg_price
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
  JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
  JOIN date_dim d_web_ret ON wr.wr_returned_date_sk = d_web_ret.d_date_sk
  JOIN time_dim t_web_ret ON wr.wr_returned_time_sk = t_web_ret.t_time_sk
  WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND i.i_brand = 'Brand#12'
    AND s.s_state = 'CA'
    AND cd_bill.cd_gender = 'M'
    AND hd_bill.hd_income_band_sk BETWEEN 3 AND 5
    AND inv.inv_quantity_on_hand > 0
    AND EXISTS (
      SELECT 1 FROM store_returns sr2
      WHERE sr2.sr_item_sk = cs.cs_item_sk
        AND sr2.sr_returned_date_sk = cs.cs_sold_date_sk
    )
  GROUP BY
    GROUPING SETS (
      (i.i_category, s.s_state, d_sold.d_year),
      (i.i_category, d_sold.d_year),
      (s.s_state, d_sold.d_year)
    )
)
SELECT
  sd.i_category,
  sd.s_state,
  sd.d_year,
  sd.total_sales,
  sd.total_discount,
  sd.sales_cnt,
  sd.avg_price,
  ROW_NUMBER() OVER (PARTITION BY sd.d_year ORDER BY sd.total_sales DESC) AS sales_rank,
  (
    SELECT COUNT(DISTINCT i2.i_category)
    FROM item i2
    WHERE i2.i_category = sd.i_category
  ) AS distinct_category_cnt
FROM sales_data sd
WHERE sd.total_sales > 1000
ORDER BY sd.d_year, sd.total_sales DESC
LIMIT 100
