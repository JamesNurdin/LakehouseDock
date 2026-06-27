WITH actor_stats AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        n.gender,
        COUNT(DISTINCT t.id) AS total_movies,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords,
        MIN(t.production_year) AS earliest_year,
        MAX(t.production_year) AS latest_year,
        COUNT(DISTINCT an.id) AS alt_name_count,
        COUNT(DISTINCT pi.id) AS birth_date_info_count,
        AVG(CAST(mi.info AS DOUBLE)) FILTER (WHERE it2.info = 'rating') AS avg_movie_rating
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON t.id = ci.movie_id
    JOIN kind_type kt ON kt.id = t.kind_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    LEFT JOIN info_type it ON it.id = pi.info_type_id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it2 ON it2.id = mi.info_type_id
    WHERE kt.kind = 'movie'
      AND t.production_year BETWEEN 2000 AND 2020
      AND (it.info = 'birth date' OR it.info IS NULL)
    GROUP BY n.id, n.name, n.gender
)
SELECT
    actor_name,
    gender,
    total_movies,
    total_keywords,
    CAST(total_keywords AS DOUBLE) / total_movies AS avg_keywords_per_movie,
    earliest_year,
    latest_year,
    alt_name_count,
    birth_date_info_count,
    avg_movie_rating
FROM actor_stats
WHERE total_movies >= 5
ORDER BY total_movies DESC
LIMIT 10
