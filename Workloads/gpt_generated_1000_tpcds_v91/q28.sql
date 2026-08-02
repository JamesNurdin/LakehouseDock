WITH filtered AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_type,
        cp.cp_catalog_number,
        d_start.d_year AS start_year,
        d_end.d_year AS end_year
    FROM catalog_page cp
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    WHERE cp.cp_type IN ('quarterly', 'monthly')
      AND cp.cp_department = 'DEPARTMENT'
      AND cp.cp_catalog_number > 20
      AND d_start.d_year = 1998
      AND d_end.d_year = 1999
      AND cp.cp_catalog_page_id NOT IN (
          SELECT cp2.cp_catalog_page_id
          FROM catalog_page cp2
          WHERE cp2.cp_type = 'monthly' AND cp2.cp_catalog_number < 10
      )
),
agg AS (
    SELECT
        cp_department AS department,
        cp_type AS page_type,
        start_year,
        COUNT(*) AS page_cnt,
        SUM(cp_catalog_number) AS total_catalog_number
    FROM filtered
    GROUP BY ROLLUP (cp_department, cp_type, start_year)
)
SELECT
    department,
    page_type,
    start_year,
    page_cnt,
    total_catalog_number,
    rank_by_total,
    CASE WHEN rank_by_total = 1 THEN 'Top' ELSE '' END AS rank_label
FROM (
    SELECT
        department,
        page_type,
        start_year,
        page_cnt,
        total_catalog_number,
        RANK() OVER (PARTITION BY department ORDER BY total_catalog_number DESC) AS rank_by_total
    FROM agg
) t
ORDER BY department, page_type, start_year, rank_by_total
LIMIT 100
