/*
Goal: Count distinct catalog pages per department that were active on non‑current days, filter by description patterns and store city patterns, exclude stores in specific counties, and rank departments by recent fiscal week.
*/
WITH page_union AS (
    SELECT
        cp_catalog_page_sk,
        cp_catalog_page_id,
        cp_department,
        cp_description,
        cp_start_date_sk,
        cp_end_date_sk
    FROM catalog_page
    WHERE regexp_like(cp_description, '(?i)sale')
    UNION ALL
    SELECT
        cp_catalog_page_sk,
        cp_catalog_page_id,
        cp_department,
        cp_description,
        cp_start_date_sk,
        cp_end_date_sk
    FROM catalog_page
    WHERE regexp_like(cp_description, '(?i)clearance')
),
date_filtered AS (
    SELECT
        d_date_sk,
        d_year,
        d_fy_week_seq,
        d_current_day
    FROM date_dim
    WHERE d_current_day = 'N'
),
store_filtered AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_city,
        s_county,
        s_closed_date_sk
    FROM store
    WHERE lower(s_city) LIKE '%town%'
)
SELECT
    pu.cp_department,
    COUNT(DISTINCT pu.cp_catalog_page_id) AS page_count,
    SUM(CASE WHEN regexp_like(pu.cp_description, '(?i)discount') THEN 1 ELSE 0 END) AS discount_pages,
    d.d_year,
    d.d_fy_week_seq,
    MAX(CONCAT(s.s_city, ' - ', s.s_store_name)) AS store_label,
    ROW_NUMBER() OVER (PARTITION BY pu.cp_department ORDER BY d.d_fy_week_seq DESC) AS dept_rank
FROM page_union pu
JOIN date_filtered d
    ON pu.cp_end_date_sk = d.d_date_sk
JOIN store_filtered s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM store s2
    WHERE s2.s_store_sk = s.s_store_sk
      AND s2.s_county IN ('Oglethorpe County', 'Raleigh County')
)
  AND regexp_extract(pu.cp_catalog_page_id, '[A-Z]{9}') = substr(pu.cp_catalog_page_id, 1, 9)
GROUP BY pu.cp_department, d.d_year, d.d_fy_week_seq
ORDER BY page_count DESC, d.d_year ASC
LIMIT 100
