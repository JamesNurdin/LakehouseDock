WITH distinct_cc AS (
  SELECT DISTINCT cc_call_center_sk
  FROM call_center
  WHERE cc_sq_ft > 0
    AND cc_gmt_offset BETWEEN -5.00 AND 5.00
),
sales_agg AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    td.t_sub_shift,
    cs.cs_sold_date_sk,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_sales_price) AS avg_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_coupon_amt) AS total_coupon_amt,
    MIN(cs.cs_wholesale_cost) AS min_wholesale_cost,
    MAX(cs.cs_wholesale_cost) AS max_wholesale_cost
  FROM catalog_sales cs
  JOIN distinct_cc dc ON cs.cs_call_center_sk = dc.cc_call_center_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE cs.cs_wholesale_cost > 25
    AND cs.cs_coupon_amt < 3000
    AND td.t_sub_shift IN ('evening', 'night')
    AND td.t_second BETWEEN 0 AND 15
  GROUP BY ROLLUP (
    cc.cc_call_center_id,
    cc.cc_name,
    td.t_sub_shift,
    cs.cs_sold_date_sk
  )
)
SELECT
  cc_call_center_id,
  cc_name,
  t_sub_shift,
  cs_sold_date_sk,
  total_sales,
  avg_sales,
  distinct_orders,
  total_coupon_amt,
  min_wholesale_cost,
  max_wholesale_cost,
  SUM(total_sales) OVER (PARTITION BY cc_call_center_id) AS sales_per_center,
  (
    SELECT SUM(total_sales)
    FROM sales_agg s2
    WHERE s2.cc_call_center_id = s1.cc_call_center_id
      AND s2.t_sub_shift = s1.t_sub_shift
      AND s2.cs_sold_date_sk IS NULL
  ) AS subtotal_sales_center_shift
FROM sales_agg s1
WHERE cs_sold_date_sk IS NOT NULL
   OR (cs_sold_date_sk IS NULL AND t_sub_shift IS NOT NULL)
ORDER BY cc_call_center_id, t_sub_shift, cs_sold_date_sk NULLS LAST
