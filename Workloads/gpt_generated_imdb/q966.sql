SELECT
    mi.info AS genre,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    COUNT(DISTINCT n.id) AS distinct_actor_count,
    COUNT(c.id) AS total_cast_entries,
    CAST(COUNT(c.id) AS DOUBLE) / NULLIF(COUNT(DISTINCT t.id), 0) AS avg_cast_per_movie
FROM title t
JOIN movie_info mi ON mi.movie_id = t.id
JOIN cast_info c ON c.movie_id = t.id
JOIN name n ON n.id = c.person_id
WHERE mi.info_type_id = 1
  AND t.production_year >= 2000
GROUP BY mi.info, t.production_year
ORDER BY movie_count DESC
LIMIT 10
