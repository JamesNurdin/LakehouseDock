WITH movie_numeric_info AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.kind AS kind,
        it.info AS info_type,
        mi.note AS numeric_value
    FROM title t
    JOIN kind_type k ON t.kind_id = k.id
    JOIN movie_info_idx mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE t.production_year IS NOT NULL
)
SELECT
    kind,
    production_year,
    COUNT(DISTINCT title_id) AS movie_count,
    AVG(CASE WHEN info_type = 'rating' THEN numeric_value END) AS avg_rating,
    AVG(CASE WHEN info_type = 'runtime' THEN numeric_value END) AS avg_runtime,
    SUM(CASE WHEN info_type = 'budget' THEN numeric_value END) AS total_budget
FROM movie_numeric_info
GROUP BY kind, production_year
HAVING COUNT(DISTINCT title_id) >= 5
ORDER BY kind, production_year
