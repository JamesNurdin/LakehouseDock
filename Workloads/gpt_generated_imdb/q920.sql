WITH decade_counts AS (
    SELECT
        kt.kind,
        floor(t.production_year / 10) * 10 AS decade,
        count(*) AS title_count,
        avg(t.production_year) AS avg_year
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
    GROUP BY
        kt.kind,
        floor(t.production_year / 10) * 10
)
SELECT
    kind,
    decade,
    title_count,
    avg_year,
    rank() OVER (PARTITION BY kind ORDER BY title_count DESC) AS decade_rank
FROM decade_counts
ORDER BY kind, decade_rank
