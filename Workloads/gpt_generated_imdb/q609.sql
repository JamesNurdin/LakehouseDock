WITH actor_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS primary_name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        COUNT(DISTINCT CASE WHEN t.production_year >= 2000 THEN ci.movie_id END) AS movies_2000_onwards,
        COUNT(DISTINCT cn.id) AS distinct_characters,
        COUNT(DISTINCT an.id) AS aka_name_count
    FROM name n
    LEFT JOIN cast_info ci
        ON ci.person_id = n.id
    LEFT JOIN title t
        ON t.id = ci.movie_id
    LEFT JOIN char_name cn
        ON cn.id = ci.person_role_id
    LEFT JOIN aka_name an
        ON an.person_id = n.id
    GROUP BY n.id, n.name, n.gender
)
SELECT
    gender,
    COUNT(*) AS actor_count,
    AVG(total_movies) AS avg_total_movies,
    AVG(movies_2000_onwards) AS avg_movies_2000_onwards,
    AVG(distinct_characters) AS avg_distinct_characters,
    AVG(aka_name_count) AS avg_aka_names
FROM actor_stats
GROUP BY gender
ORDER BY avg_total_movies DESC
