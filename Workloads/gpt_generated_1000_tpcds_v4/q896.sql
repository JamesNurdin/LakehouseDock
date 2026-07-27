WITH page_sales AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM tpcds.catalog_page cp
    JOIN tpcds.catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_quantity > 30
        AND cs.cs_ext_sales_price BETWEEN 1000 AND 5000
        AND cp.cp_catalog_number IN (2, 14, 16)
        AND cp.cp_end_date_sk BETWEEN 2450900 AND 2451200
        AND cs.cs_call_center_sk IN (10, 16)
    GROUP BY cp.cp_catalog_page_sk, cp.cp_catalog_page_id, cp.cp_department, cp.cp_catalog_number
)
SELECT
    cp_catalog_page_id,
    cp_department,
    cp_catalog_number,
    total_sales,
    total_quantity,
    avg_discount,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_sales DESC) AS dept_sales_rank,
    CASE
        WHEN total_sales > 20000 THEN 'High'
        WHEN total_sales > 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM page_sales
ORDER BY dept_sales_rank, total_sales DESC
LIMIT 100
