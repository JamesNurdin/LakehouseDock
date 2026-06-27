WITH actor_movie_details AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        n.gender,
        t.id AS movie_id,
        t.production_year,
        CAST(mi.info AS double) AS rating,
        ct.kind AS company_type_kind
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON t.id = ci.movie_id
    JOIN kind_type kt ON kt.id = t.kind_id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON it.id = mi.info_type_id AND it.info = 'rating'
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON ct.id = mc.company_type_id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2000
)
SELECT
    actor_id,
    actor_name,
    gender,
    COUNT(DISTINCT movie_id) AS total_movies,
    AVG(production_year) AS avg_production_year,
    AVG(rating) AS avg_rating,
    COUNT(DISTINCT company_type_kind) AS distinct_company_type_count
FROM actor_movie_details
GROUP BY actor_id, actor_name, gender
ORDER BY total_movies DESC
LIMIT 10
