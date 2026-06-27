-- Movies and cast analytics by production year and keyword
SELECT
    t.production_year,
    mk.keyword_id,
    COUNT(DISTINCT t.id) AS movie_count,
    COUNT(ci.id) AS total_cast_entries,
    COUNT(DISTINCT ci.person_id) AS total_distinct_actors,
    COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_actor_count,
    COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_actor_count,
    CAST(COUNT(ci.id) AS DOUBLE) / NULLIF(COUNT(DISTINCT t.id), 0) AS avg_cast_per_movie
FROM title t
JOIN movie_keyword mk
    ON mk.movie_id = t.id
JOIN cast_info ci
    ON ci.movie_id = t.id
JOIN name n
    ON ci.person_id = n.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, mk.keyword_id
ORDER BY t.production_year DESC, movie_count DESC
