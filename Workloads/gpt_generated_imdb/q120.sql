WITH movie_info AS (
    SELECT
        mi.movie_id,
        it.info AS info,
        mi.note,
        t.production_year,
        t.kind_id
    FROM movie_info_idx mi
    JOIN title t
        ON mi.movie_id = t.id
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE t.kind_id = 1
      AND t.production_year IS NOT NULL
)
SELECT
    info,
    COUNT(DISTINCT movie_id) AS movie_count,
    AVG(note) AS avg_note,
    MIN(production_year) AS earliest_production_year,
    MAX(production_year) AS latest_production_year,
    COUNT(DISTINCT production_year) AS distinct_production_years
FROM movie_info
GROUP BY info
ORDER BY movie_count DESC
LIMIT 20
