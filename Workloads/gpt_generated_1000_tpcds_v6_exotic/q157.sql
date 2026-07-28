WITH start_pages AS (
    SELECT
        cp.cp_catalog_page_id AS cp_id,
        cp.cp_department AS department,
        cp.cp_catalog_number AS catalog_number,
        d.d_date AS start_date,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY d.d_date DESC) AS dept_start_page_rank
    FROM catalog_page cp
    JOIN date_dim d
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cp.cp_type = 'monthly'
),
end_pages AS (
    SELECT
        cp.cp_catalog_page_id AS cp_id,
        cp.cp_department AS department,
        cp.cp_catalog_number AS catalog_number,
        d.d_date AS end_date,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY d.d_date DESC) AS dept_end_page_rank
    FROM catalog_page cp
    JOIN date_dim d
        ON cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cp.cp_type = 'monthly'
)
SELECT
    cp_id,
    department,
    catalog_number,
    start_or_end,
    page_date,
    rank
FROM (
    SELECT
        cp_id,
        department,
        catalog_number,
        'start' AS start_or_end,
        start_date AS page_date,
        dept_start_page_rank AS rank
    FROM start_pages
    UNION ALL
    SELECT
        cp_id,
        department,
        catalog_number,
        'end' AS start_or_end,
        end_date AS page_date,
        dept_end_page_rank AS rank
    FROM end_pages
) combined
ORDER BY department, rank, start_or_end
