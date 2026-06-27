WITH movie_ratings AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS DOUBLE) AS rating
    FROM movie_info mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k
        ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_companies AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT
    n.id AS actor_id,
    n.name AS actor_name,
    n.gender,
    COUNT(DISTINCT t.id) AS total_movies,
    AVG(t.production_year) AS avg_production_year,
    AVG(mr.rating) AS avg_rating,
    COALESCE(SUM(mk.keyword_count), 0) AS total_keywords,
    COALESCE(SUM(mc.company_count), 0) AS total_companies
FROM cast_info ci
JOIN name n
    ON ci.person_id = n.id
JOIN title t
    ON ci.movie_id = t.id
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN movie_ratings mr
    ON t.id = mr.movie_id
LEFT JOIN movie_keywords mk
    ON t.id = mk.movie_id
LEFT JOIN movie_companies mc
    ON t.id = mc.movie_id
WHERE kt.kind = 'movie'
GROUP BY n.id, n.name, n.gender
ORDER BY total_movies DESC
LIMIT 10
