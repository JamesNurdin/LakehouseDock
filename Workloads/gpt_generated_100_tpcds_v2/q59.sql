WITH quarterly_sales AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        d.d_year,
        d.d_quarter_seq,
        SUM(cs.cs_ext_sales_price) AS quarterly_sales
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cp.cp_department = 'Electronics'
      AND cd.cd_education_status = '4 yr Degree'
    GROUP BY
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        d.d_year,
        d.d_quarter_seq
)
SELECT
    qs.cp_catalog_page_id,
    qs.cp_department,
    AVG(qs.quarterly_sales) AS avg_quarterly_sales,
    COUNT(*) AS quarters_count
FROM quarterly_sales qs
GROUP BY
    qs.cp_catalog_page_id,
    qs.cp_department
HAVING AVG(qs.quarterly_sales) > 100000
ORDER BY avg_quarterly_sales DESC
LIMIT 10
