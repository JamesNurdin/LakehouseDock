WITH agg_store AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        s.s_country,
        s.s_tax_percentage,
        s.s_gmt_offset,
        COUNT(*) AS store_row_cnt
    FROM store s
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d_closed.d_fy_week_seq BETWEEN 10 AND 20
      AND s.s_tax_percentage > 0.05
      AND s.s_gmt_offset BETWEEN -5 AND -4
    GROUP BY s.s_store_sk, s.s_state, s.s_country, s.s_tax_percentage, s.s_gmt_offset
),
main1 AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        d_end.d_year,
        a.s_country,
        CASE WHEN a.s_tax_percentage > 0.07 THEN 'HIGH' ELSE 'NORMAL' END AS tax_level,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY d_end.d_date DESC) AS dept_rn,
        t.loc AS location
    FROM catalog_page cp
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_end.d_date_sk
    JOIN agg_store a
        ON a.s_store_sk = s.s_store_sk
    CROSS JOIN UNNEST(ARRAY[a.s_state, a.s_country]) AS t(loc)
    WHERE d_end.d_year = 2002
      AND cp.cp_catalog_number > 10
      AND cp.cp_end_date_sk IN (2450994, 2451361)
      AND cp.cp_description LIKE '%years%'
      AND a.s_tax_percentage BETWEEN 0.05 AND 0.09
      AND a.s_gmt_offset BETWEEN -5 AND -4
),
main2 AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        d_start.d_year,
        a.s_country,
        CASE WHEN a.s_tax_percentage > 0.07 THEN 'HIGH' ELSE 'NORMAL' END AS tax_level,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY d_start.d_date DESC) AS dept_rn,
        t.loc AS location
    FROM catalog_page cp
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_start.d_date_sk
    JOIN agg_store a
        ON a.s_store_sk = s.s_store_sk
    CROSS JOIN UNNEST(ARRAY[a.s_state, a.s_country]) AS t(loc)
    WHERE d_start.d_year = 2001
      AND cp.cp_catalog_number BETWEEN 5 AND 20
      AND cp.cp_start_date_sk IN (2450905, 2450964)
      AND cp.cp_description LIKE '%years%'
      AND a.s_tax_percentage BETWEEN 0.05 AND 0.09
      AND a.s_gmt_offset BETWEEN -5 AND -4
)
SELECT
    cp_catalog_page_id,
    cp_department,
    cp_catalog_number,
    d_year,
    s_country,
    tax_level,
    dept_rn,
    location
FROM main1
UNION DISTINCT
SELECT
    cp_catalog_page_id,
    cp_department,
    cp_catalog_number,
    d_year,
    s_country,
    tax_level,
    dept_rn,
    location
FROM main2
ORDER BY tax_level DESC, dept_rn ASC
LIMIT 100
