WITH rating_per_movie AS (
    SELECT
        mi.movie_id,
        TRY_CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
movie_production AS (
    SELECT
        t.id AS movie_id,
        c.id AS company_id,
        c.name AS company_name,
        t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE kt.kind = 'movie'
      AND ct.kind = 'production'
      AND t.production_year BETWEEN 2000 AND 2020
),
company_movie_rating AS (
    SELECT
        mp.company_id,
        mp.company_name,
        rp.rating
    FROM movie_production mp
    LEFT JOIN rating_per_movie rp ON mp.movie_id = rp.movie_id
    WHERE rp.rating IS NOT NULL
),
company_rating_agg AS (
    SELECT
        cmr.company_id,
        cmr.company_name,
        AVG(cmr.rating) AS avg_rating
    FROM company_movie_rating cmr
    GROUP BY cmr.company_id, cmr.company_name
),
company_movie_counts AS (
    SELECT
        mp.company_id,
        mp.company_name,
        COUNT(DISTINCT mp.movie_id) AS movie_count
    FROM movie_production mp
    GROUP BY mp.company_id, mp.company_name
),
company_actor_counts AS (
    SELECT
        mp.company_id,
        mp.company_name,
        COUNT(DISTINCT ci.person_id) AS distinct_actor_count
    FROM movie_production mp
    JOIN cast_info ci ON ci.movie_id = mp.movie_id
    GROUP BY mp.company_id, mp.company_name
)
SELECT
    cmc.company_name,
    cmc.movie_count,
    cac.distinct_actor_count,
    cra.avg_rating
FROM company_movie_counts cmc
JOIN company_actor_counts cac
    ON cmc.company_id = cac.company_id
JOIN company_rating_agg cra
    ON cmc.company_id = cra.company_id
ORDER BY cmc.movie_count DESC
LIMIT 10
