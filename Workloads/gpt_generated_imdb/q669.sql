WITH keyword_movie_actor AS (
    SELECT
        mk.keyword_id AS keyword_id,
        mk.movie_id AS movie_id,
        ci.person_id AS person_id,
        n.gender AS gender,
        t.production_year AS production_year
    FROM movie_keyword mk
    JOIN title t
        ON mk.movie_id = t.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN name n
        ON ci.person_id = n.id
)
SELECT
    km.keyword_id,
    COUNT(DISTINCT km.movie_id) AS movie_count,
    AVG(km.production_year) AS avg_production_year,
    COUNT(DISTINCT km.person_id) AS distinct_actor_count,
    COUNT(DISTINCT CASE WHEN km.gender = 'M' THEN km.person_id END) AS male_actor_count,
    COUNT(DISTINCT CASE WHEN km.gender = 'F' THEN km.person_id END) AS female_actor_count
FROM keyword_movie_actor km
GROUP BY km.keyword_id
ORDER BY movie_count DESC
LIMIT 10
