WITH titles_by_year AS (
    SELECT
        k.kind,
        floor(t.production_year) AS prod_year,
        COUNT(*) AS title_cnt
    FROM title t
    JOIN kind_type k ON t.kind_id = k.id
    WHERE t.production_year IS NOT NULL
    GROUP BY k.kind, floor(t.production_year)
),
ranked_titles AS (
    SELECT
        kind,
        prod_year,
        title_cnt,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY title_cnt DESC) AS rn
    FROM titles_by_year
)
SELECT
    kind,
    prod_year,
    title_cnt
FROM ranked_titles
WHERE rn <= 5
ORDER BY kind, title_cnt DESC
