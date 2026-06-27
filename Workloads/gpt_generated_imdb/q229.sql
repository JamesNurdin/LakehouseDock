WITH rating_by_movie AS (
    SELECT
        mi.movie_id,
        AVG(CAST(mi.info AS DOUBLE)) AS avg_rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
),
actor_count AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_count AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS num_keywords
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_count AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    t.id AS movie_id,
    t.title,
    t.production_year,
    r.avg_rating,
    a.num_actors,
    k.num_keywords,
    c.num_companies
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN rating_by_movie r ON r.movie_id = t.id
LEFT JOIN actor_count a ON a.movie_id = t.id
LEFT JOIN keyword_count k ON k.movie_id = t.id
LEFT JOIN company_count c ON c.movie_id = t.id
WHERE kt.kind = 'movie'
  AND t.production_year >= 2000
ORDER BY r.avg_rating DESC NULLS LAST
LIMIT 100
