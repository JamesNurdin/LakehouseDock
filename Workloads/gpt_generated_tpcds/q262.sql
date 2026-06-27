/*
  Sales vs. Returns analysis per catalog department and page number.
  Aggregates sales metrics from catalog_sales and return metrics from catalog_returns,
  joining both to catalog_page using only the allowed join keys.
*/
WITH sales_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_page_number,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_department, cp.cp_catalog_page_number
),
returns_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_page_number,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_department, cp.cp_catalog_page_number
)
SELECT
    s.cp_department,
    s.cp_catalog_page_number,
    s.total_sales,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales,
    s.total_net_profit,
    s.total_discount,
    s.total_quantity,
    s.distinct_orders,
    COALESCE(r.distinct_return_orders, 0) AS distinct_return_orders
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cp_department = r.cp_department
   AND s.cp_catalog_page_number = r.cp_catalog_page_number
ORDER BY s.total_sales DESC
LIMIT 20
