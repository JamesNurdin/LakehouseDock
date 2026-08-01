/* goal: Compare yearly sales and web return amounts by warehouse, include subtotals, categorize amounts, and assign a global row number */
WITH sales_data AS (
    SELECT
        d.d_year,
        w.w_warehouse_name,
        'sales' AS metric_type,
        SUM(cs.cs_ext_sales_price) AS total_amount,
        SUM(cs.cs_quantity) AS total_qty,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 1000000 THEN 'High' ELSE 'Low' END AS amount_category,
        (SELECT COUNT(*) FROM call_center cc_sub WHERE cc_sub.cc_division = 1) AS division_one_cc_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND cs.cs_warehouse_sk IN (
          SELECT w2.w_warehouse_sk FROM warehouse w2 WHERE w2.w_country = 'United States'
      )
      AND EXISTS (
          SELECT 1 FROM call_center cc WHERE cc.cc_call_center_sk = cs.cs_call_center_sk AND cc.cc_state = 'CA'
      )
    GROUP BY GROUPING SETS ((d.d_year, w.w_warehouse_name), (d.d_year), ())
),
returns_data AS (
    SELECT
        d.d_year,
        NULL AS w_warehouse_name,
        'returns' AS metric_type,
        SUM(wr.wr_return_amt) AS total_amount,
        SUM(wr.wr_return_quantity) AS total_qty,
        CASE WHEN SUM(wr.wr_return_amt) > 500000 THEN 'High' ELSE 'Low' END AS amount_category,
        (SELECT COUNT(*) FROM call_center cc_sub WHERE cc_sub.cc_division = 1) AS division_one_cc_count
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY GROUPING SETS ((d.d_year), ())
)
SELECT
    combined.d_year,
    combined.w_warehouse_name,
    combined.metric_type,
    combined.total_amount,
    combined.total_qty,
    combined.amount_category,
    combined.division_one_cc_count,
    ROW_NUMBER() OVER (ORDER BY combined.d_year, combined.w_warehouse_name) AS row_num
FROM (
    SELECT * FROM sales_data
    UNION
    SELECT * FROM returns_data
) AS combined
ORDER BY combined.d_year, combined.w_warehouse_name
LIMIT 100
