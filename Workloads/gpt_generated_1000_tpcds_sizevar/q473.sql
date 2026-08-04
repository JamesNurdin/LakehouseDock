WITH
  common_orders AS (
    SELECT cs_order_number FROM catalog_sales
    INTERSECT
    SELECT wr_order_number FROM web_returns
  ),
  cs_filtered AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_net_paid_inc_tax > 1000
      AND cs_order_number IN (SELECT cs_order_number FROM common_orders)
  ),
  cs_agg AS (
    SELECT
      cs_sold_date_sk,
      cs_warehouse_sk,
      cs_bill_hdemo_sk,
      SUM(cs_net_paid_inc_tax) AS sum_net_paid_inc_tax,
      SUM(cs_ext_sales_price) AS sum_ext_sales_price,
      COUNT(*) AS cnt_cs_orders
    FROM cs_filtered
    GROUP BY cs_sold_date_sk, cs_warehouse_sk, cs_bill_hdemo_sk
  ),
  ss_agg AS (
    SELECT
      ss_sold_date_sk,
      ss_hdemo_sk,
      SUM(ss_net_paid) AS sum_ss_net_paid,
      COUNT(*) AS cnt_ss_orders
    FROM store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_sold_date_sk, ss_hdemo_sk
  ),
  wr_agg AS (
    SELECT
      wr_returned_date_sk,
      SUM(wr_net_loss) AS sum_wr_net_loss,
      COUNT(*) AS cnt_wr_returns
    FROM web_returns
    WHERE wr_return_amt > 0
    GROUP BY wr_returned_date_sk
  )
SELECT *
FROM (
  SELECT
    d.d_year,
    w.w_warehouse_name,
    CASE
      WHEN ca.sum_net_paid_inc_tax + sa.sum_ss_net_paid > 50000 THEN 'High'
      ELSE 'Low'
    END AS profit_category,
    (ca.sum_net_paid_inc_tax + sa.sum_ss_net_paid) AS total_sales,
    ca.cnt_cs_orders,
    sa.cnt_ss_orders,
    wa.sum_wr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY (ca.sum_net_paid_inc_tax + sa.sum_ss_net_paid) DESC) AS rn
  FROM cs_agg ca
  JOIN date_dim d ON ca.cs_sold_date_sk = d.d_date_sk
  JOIN warehouse w ON ca.cs_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd ON ca.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN ss_agg sa ON sa.ss_sold_date_sk = d.d_date_sk
    AND sa.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN wr_agg wa ON wa.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND w.w_state = 'CA'
    AND hd.hd_income_band_sk = 5
    AND d.d_current_year = 'Y'
    AND d.d_holiday = 'N'
    AND w.w_gmt_offset = -5.00
    AND hd.hd_vehicle_count >= 1
    AND hd.hd_dep_count <= 5
    AND ca.sum_ext_sales_price > 10000
    AND ca.cnt_cs_orders >= 5
    AND wa.cnt_wr_returns > 0
) t
WHERE rn <= 5
ORDER BY t.d_year, t.total_sales DESC
LIMIT 100
