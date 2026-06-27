WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
    GROUP BY t.id, t.production_year
),
movie_company AS (
    SELECT DISTINCT
        mc.movie_id,
        ct.kind AS company_type_kind
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT
    mcc.production_year,
    mc.company_type_kind,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(mcc.cast_count) AS avg_cast_per_movie
FROM movie_company mc
JOIN movie_cast_counts mcc ON mcc.movie_id = mc.movie_id
GROUP BY mcc.production_year, mc.company_type_kind
ORDER BY mcc.production_year DESC, mc.company_type_kind
