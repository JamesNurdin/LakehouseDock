WITH movie_cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_company AS (
    SELECT DISTINCT
        t.id AS movie_id,
        t.production_year,
        ct.kind AS company_type,
        mcc.cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN movie_cast_counts mcc ON mcc.movie_id = t.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
)
SELECT
    mc.production_year,
    mc.company_type,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    SUM(mc.cast_count) AS total_cast_members,
    SUM(mc.cast_count) / COUNT(DISTINCT mc.movie_id) AS avg_cast_per_movie
FROM movie_company mc
GROUP BY mc.production_year, mc.company_type
ORDER BY mc.production_year DESC, movie_count DESC
LIMIT 20
