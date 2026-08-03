WITH excluded_pages AS (
    SELECT cp_catalog_page_sk
    FROM catalog_page
    EXCEPT
    SELECT cr_catalog_page_sk
    FROM catalog_returns
),
filtered_pages AS (
    SELECT cp_catalog_page_sk,
           cp_description,
           cp_type,
           cp_catalog_page_number
    FROM catalog_page
    WHERE regexp_like(cp_description, '(?i)discount')
      AND cp_type LIKE 'C%'
),
joined AS (
    SELECT cr.cr_returned_date_sk,
           cr.cr_returned_time_sk,
           cr.cr_return_quantity,
           cr.cr_return_amount,
           cr.cr_reason_sk,
           cr.cr_catalog_page_sk,
           cr.cr_warehouse_sk,
           r.r_reason_desc,
           cp.cp_description,
           cp.cp_type,
           cp.cp_catalog_page_number,
           w.w_warehouse_name,
           t.t_meal_time
    FROM catalog_returns cr
    JOIN filtered_pages cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cp.cp_catalog_page_sk NOT IN (SELECT cp_catalog_page_sk FROM excluded_pages)
      AND regexp_extract(cp.cp_description, '(\\d+)%') IS NOT NULL
),
aggregated AS (
    SELECT
        cp.cp_catalog_page_number,
        cp.cp_type,
        COUNT(*) AS total_returns,
        SUM(j.cr_return_amount) AS total_return_amount,
        AVG(j.cr_return_amount) AS avg_return_amount,
        CASE WHEN SUM(j.cr_return_amount) > 10000 THEN 'High' ELSE 'Low' END AS return_category
    FROM joined j
    JOIN catalog_page cp ON j.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_description LIKE '%sale%'
    GROUP BY cp.cp_catalog_page_number, cp.cp_type
)
SELECT
    ag.cp_catalog_page_number,
    ag.cp_type,
    ag.total_returns,
    ag.total_return_amount,
    ag.avg_return_amount,
    ag.return_category,
    ROW_NUMBER() OVER (PARTITION BY ag.cp_type ORDER BY ag.total_return_amount DESC) AS type_rank
FROM aggregated ag
ORDER BY ag.total_return_amount DESC
LIMIT 100
