WITH sales_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        CONCAT(cp.cp_department, '-', cp.cp_type) AS dept_type,
        regexp_extract(cp.cp_description, '(?i)(sale|discount)', 1) AS keyword,
        SUM(cs.cs_net_paid) AS total_metric,
        COUNT(*) AS cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(cp.cp_description, '(?i)sale')
      AND cp.cp_department LIKE 'Beauty%'
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_type,
        regexp_extract(cp.cp_description, '(?i)(sale|discount)', 1)
),
returns_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        CONCAT(cp.cp_department, '-', cp.cp_type) AS dept_type,
        regexp_extract(cp.cp_description, '(?i)(sale|discount)', 1) AS keyword,
        SUM(cr.cr_net_loss) AS total_metric,
        COUNT(*) AS cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
                         AND cr.cr_item_sk = cs.cs_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cp.cp_description LIKE '%discount%'
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_type,
        regexp_extract(cp.cp_description, '(?i)(sale|discount)', 1)
)
SELECT
    sa.cp_catalog_page_id,
    sa.dept_type,
    sa.keyword,
    sa.total_metric,
    'sales' AS source,
    sa.cnt
FROM sales_agg sa
UNION ALL
SELECT
    ra.cp_catalog_page_id,
    ra.dept_type,
    ra.keyword,
    ra.total_metric,
    'returns' AS source,
    ra.cnt
FROM returns_agg ra
LIMIT 100
