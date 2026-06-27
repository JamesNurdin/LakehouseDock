WITH movie_ratings AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating' AND mi.info IS NOT NULL
),
movie_actors AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT
    ct.kind AS company_type,
    kt.kind AS movie_kind,
    t.production_year,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(r.rating) AS avg_rating,
    SUM(ma.actor_count) AS total_actors
FROM movie_companies mc
JOIN company_type ct ON mc.company_type_id = ct.id
JOIN title t ON mc.movie_id = t.id
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_ratings r ON mc.movie_id = r.movie_id
LEFT JOIN movie_actors ma ON mc.movie_id = ma.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY ct.kind, kt.kind, t.production_year
ORDER BY ct.kind, kt.kind, t.production_year DESC
LIMIT 100
