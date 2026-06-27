WITH total_per_kind AS (
    SELECT
        kind_type.kind,
        COUNT(title.id) AS total_titles
    FROM title
    JOIN kind_type
        ON title.kind_id = kind_type.id
    GROUP BY kind_type.kind
),
yearly_counts AS (
    SELECT
        kind_type.kind,
        CAST(title.production_year AS integer) AS prod_year,
        COUNT(title.id) AS yearly_titles
    FROM title
    JOIN kind_type
        ON title.kind_id = kind_type.id
    WHERE title.production_year IS NOT NULL
    GROUP BY kind_type.kind, CAST(title.production_year AS integer)
)
SELECT
    yc.kind,
    yc.prod_year,
    yc.yearly_titles,
    tp.total_titles,
    (yc.yearly_titles * 100.0 / tp.total_titles) AS pct_of_kind
FROM yearly_counts yc
JOIN total_per_kind tp
    ON yc.kind = tp.kind
ORDER BY pct_of_kind DESC
LIMIT 50
