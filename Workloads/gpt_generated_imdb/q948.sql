WITH cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM title t
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.production_year
),
movie_company_type AS (
    SELECT DISTINCT
        mc.movie_id,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_type ct
        ON mc.company_type_id = ct.id
)
SELECT
    cc.production_year,
    mct.company_type,
    COUNT(*) AS movies_count,
    ROUND(AVG(cc.cast_cnt), 2) AS avg_cast_per_movie
FROM cast_counts cc
JOIN movie_company_type mct
    ON mct.movie_id = cc.movie_id
WHERE cc.production_year >= 2000
GROUP BY cc.production_year, mct.company_type
ORDER BY cc.production_year DESC, movies_count DESC
