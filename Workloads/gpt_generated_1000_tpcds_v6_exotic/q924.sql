WITH sales_data AS (
  SELECT
    w.w_state,
    cd.cd_gender,
    cp.cp_department,
    SUM(cs.cs_ext_sales_price) AS sales_amount,
    0.0 AS returns_amount,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    AVG(cs.cs_quantity) AS avg_qty,
    'sales' AS src
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE w.w_zip = '29231'
    AND cs.cs_quantity > 5
    AND cp.cp_department = 'Sports'
  GROUP BY w.w_state, cd.cd_gender, cp.cp_department
),
returns_data AS (
  SELECT
    NULL AS w_state,
    cd.cd_gender,
    NULL AS cp_department,
    0.0 AS sales_amount,
    SUM(wr.wr_return_amt) AS returns_amount,
    0 AS orders,
    NULL AS avg_qty,
    'returns' AS src
  FROM web_returns wr
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_link_count > 10
    AND wr.wr_return_ship_cost > 100
    AND cd.cd_gender = 'M'
  GROUP BY cd.cd_gender
)
SELECT
  COALESCE(s.w_state, 'UNKNOWN') AS state,
  s.cd_gender,
  COALESCE(s.cp_department, 'UNKNOWN') AS department,
  SUM(s.sales_amount) AS total_sales,
  SUM(s.returns_amount) AS total_returns,
  SUM(s.orders) AS total_orders,
  AVG(s.avg_qty) AS avg_quantity
FROM (
  SELECT * FROM sales_data
  UNION ALL
  SELECT * FROM returns_data
) s
GROUP BY COALESCE(s.w_state, 'UNKNOWN'), s.cd_gender, COALESCE(s.cp_department, 'UNKNOWN')
ORDER BY total_sales DESC
LIMIT 100
