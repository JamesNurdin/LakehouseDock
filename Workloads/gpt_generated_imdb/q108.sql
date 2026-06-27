WITH info_agg AS (
    SELECT
        movie_id,
        COUNT(DISTINCT info_type_id) AS distinct_info_type_cnt,
        SUM(note) AS total_note
    FROM movie_info_idx
    GROUP BY movie_id
)
SELECT
    kt.kind,
    COUNT(DISTINCT t.id) AS title_cnt,
    AVG(t.production_year) AS avg_production_year,
    SUM(COALESCE(ia.distinct_info_type_cnt, 0)) AS total_distinct_info_type_cnt,
    SUM(COALESCE(ia.total_note, 0)) AS total_note
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN info_agg ia ON ia.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY kt.kind
ORDER BY title_cnt DESC
LIMIT 10
