WITH sales_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS sales_transactions,
        AVG(ss_sales_price) AS avg_sales_price
    FROM store_sales
    WHERE ss_sales_price > 15.00
      AND ss_quantity >= 1
    GROUP BY ss_sold_date_sk, ss_item_sk
    HAVING SUM(ss_ext_sales_price) > 100.00
)
SELECT
    d.d_date,
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    ws.web_site_id,
    ws.web_state,
    sa.total_sales,
    sa.avg_sales_price,
    sa.sales_transactions,
    (
        SELECT MAX(s3.ss_sales_price)
        FROM store_sales s3
        WHERE s3.ss_item_sk = sa.ss_item_sk
    ) AS max_item_price,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_department = cp.cp_department
              AND cp2.cp_start_date_sk = d.d_date_sk
              AND cp2.cp_catalog_page_number = cp.cp_catalog_page_number
        ) THEN 'Yes' ELSE 'No' END AS same_dept_page_flag
FROM sales_agg sa
JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-01-31'
  AND d.d_current_month = 'Y'
  AND cp.cp_catalog_page_number IN (1, 7, 9)
  AND cp.cp_type = 'A'
  AND ws.web_state = 'CA'
  AND ws.web_gmt_offset BETWEEN -8.00 AND -5.00
ORDER BY sa.total_sales DESC
LIMIT 100
