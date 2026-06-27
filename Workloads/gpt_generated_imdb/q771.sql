WITH rating_movies AS (
    SELECT
        mi.movie_id,
        TRY_CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
movie_actors AS (
    SELECT
        ci.movie_id,
        ci.person_id
    FROM cast_info ci
),
movie_production_companies AS (
    SELECT
        mc.movie_id,
        mc.company_id
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production company'
)
SELECT
    t.production_year,
    kt.kind AS title_kind,
    COUNT(DISTINCT t.id) AS total_movies,
    AVG(r.rating) AS avg_rating,
    COUNT(DISTINCT ma.person_id) AS distinct_actors,
    COUNT(DISTINCT pc.company_id) AS distinct_production_companies
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN rating_movies r ON t.id = r.movie_id
LEFT JOIN movie_actors ma ON t.id = ma.movie_id
LEFT JOIN movie_production_companies pc ON t.id = pc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, total_movies DESC
LIMIT 20
