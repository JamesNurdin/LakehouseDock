/* goal: Compare total sales and profit performance of quarterly vs monthly catalog pages, enriched with average wholesale cost per warehouse, using a CTE, a scalar subquery, CASE logic, and a UNION ALL set operation. */
WITH sales_by_page AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_type,
        cp.cp_catalog_page_number,
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY
        cp.cp_catalog_page_sk,
        cp.cp_type,
        cp.cp_catalog_page_number,
        cs.cs_warehouse_sk
)
SELECT
    s.cp_type,
    s.cp_catalog_page_number,
    s.cs_warehouse_sk,
    s.total_sales,
    s.total_profit,
    CASE WHEN s.total_profit > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    (
        SELECT AVG(cs2.cs_wholesale_cost)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = s.cs_warehouse_sk
    ) AS avg_wholesale_cost_warehouse
FROM sales_by_page s
WHERE s.cp_type = 'quarterly'
  AND s.total_sales > 10000

UNION ALL

SELECT
    s.cp_type,
    s.cp_catalog_page_number,
    s.cs_warehouse_sk,
    s.total_sales,
    s.total_profit,
    CASE WHEN s.total_profit > 8000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    (
        SELECT AVG(cs2.cs_wholesale_cost)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = s.cs_warehouse_sk
    ) AS avg_wholesale_cost_warehouse
FROM sales_by_page s
WHERE s.cp_type = 'monthly'
  AND s.total_sales > 8000

ORDER BY total_sales DESC
LIMIT 100
