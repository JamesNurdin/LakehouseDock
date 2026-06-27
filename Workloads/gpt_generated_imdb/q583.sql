WITH movie_info_combined AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        it.id AS info_type_id,
        it.info AS info_type_name,
        mi.info AS movie_info,
        mi.note AS movie_info_note,
        mi_idx.note AS movie_info_idx_note
    FROM title t
    JOIN movie_info mi
        ON mi.movie_id = t.id
    JOIN info_type it
        ON it.id = mi.info_type_id
    LEFT JOIN movie_info_idx mi_idx
        ON mi_idx.movie_id = t.id
        AND mi_idx.info_type_id = it.id
)
SELECT
    production_year,
    info_type_name,
    COUNT(DISTINCT movie_id) AS distinct_movie_count,
    COUNT(*) AS total_info_entries,
    AVG(movie_info_idx_note) AS avg_idx_note
FROM movie_info_combined
WHERE production_year >= 2000
GROUP BY production_year, info_type_name
ORDER BY production_year DESC, distinct_movie_count DESC
LIMIT 20
