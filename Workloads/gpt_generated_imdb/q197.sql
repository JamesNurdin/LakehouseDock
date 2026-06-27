WITH movie_info_agg AS (
    SELECT
        mi.movie_id,
        AVG(CASE WHEN it.info = 'budget' THEN TRY_CAST(mi.info AS DOUBLE) END) AS avg_budget,
        AVG(CASE WHEN it.info = 'rating' THEN TRY_CAST(mi.info AS DOUBLE) END) AS avg_rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
),
movie_keyword_agg AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
actor_stats AS (
    SELECT
        n.id,
        n.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(mi.avg_budget) AS avg_movie_budget,
        AVG(mi.avg_rating) AS avg_movie_rating,
        SUM(mk.keyword_count) AS total_keyword_count
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_info_agg mi ON mi.movie_id = t.id
    LEFT JOIN movie_keyword_agg mk ON mk.movie_id = t.id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2000
    GROUP BY n.id, n.name
)
SELECT
    id AS person_id,
    name AS person_name,
    movie_count,
    avg_movie_budget,
    avg_movie_rating,
    total_keyword_count,
    RANK() OVER (ORDER BY movie_count DESC) AS rank
FROM actor_stats
ORDER BY movie_count DESC
LIMIT 10
