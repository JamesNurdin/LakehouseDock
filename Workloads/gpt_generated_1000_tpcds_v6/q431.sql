WITH filtered_pages AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number
    FROM tpcds.catalog_page AS cp
    WHERE cp.cp_department = 'DEPARTMENT'
      AND cp.cp_catalog_page_number IN (3, 14)
      AND cp.cp_catalog_number = 19
)
SELECT
    fp.cp_department,
    fp.cp_catalog_number,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(cs.cs_order_number) AS sales_orders,
    MIN(cs.cs_wholesale_cost) AS min_wholesale_cost,
    MAX(cs.cs_net_profit) AS max_net_profit
FROM filtered_pages AS fp
LEFT JOIN tpcds.catalog_sales AS cs
    ON cs.cs_catalog_page_sk = fp.cp_catalog_page_sk
   AND cs.cs_ext_discount_amt > 1000
   AND cs.cs_ship_addr_sk = 5167051
   AND cs.cs_wholesale_cost < 50
GROUP BY
    fp.cp_department,
    fp.cp_catalog_number
LIMIT 100
