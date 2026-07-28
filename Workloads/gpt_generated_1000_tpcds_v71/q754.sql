WITH distinct_sales AS (
  SELECT DISTINCT cs_order_number, cs_catalog_page_sk, cs_ext_sales_price, cs_net_profit, cs_wholesale_cost, cs_net_paid_inc_ship_tax
  FROM catalog_sales
  WHERE cs_wholesale_cost > 10
    AND cs_net_paid_inc_ship_tax BETWEEN 1000 AND 3000
    AND cs_ext_sales_price > 0
),
aggregated AS (
  SELECT
    cp.cp_department AS department,
    cp.cp_catalog_number AS catalog_number,
    COUNT(DISTINCT ds.cs_order_number) AS distinct_orders,
    SUM(ds.cs_ext_sales_price) AS total_sales,
    AVG(ds.cs_net_profit) AS avg_profit,
    CASE WHEN AVG(ds.cs_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_category
  FROM distinct_sales ds
  JOIN catalog_page cp
    ON ds.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cp.cp_end_date_sk > 2450900
    AND cp.cp_start_date_sk < 2451100
    AND cp.cp_department = 'DEPARTMENT'
  GROUP BY cp.cp_department, cp.cp_catalog_number
)
SELECT
  department,
  catalog_number,
  distinct_orders,
  total_sales,
  avg_profit,
  profit_category,
  RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
  SUM(total_sales) OVER (PARTITION BY department ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_by_dept
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
