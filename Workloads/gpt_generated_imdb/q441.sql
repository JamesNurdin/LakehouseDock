WITH movie_cast AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_companies_agg AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_keywords_agg AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    t.production_year,
    kt.kind,
    COUNT(DISTINCT t.id) AS movie_cnt,
    SUM(COALESCE(mc.cast_cnt, 0)) AS total_cast_members,
    SUM(COALESCE(mco.company_cnt, 0)) AS total_companies,
    SUM(COALESCE(mk.keyword_cnt, 0)) AS total_keywords
FROM title t
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN movie_cast mc
    ON mc.movie_id = t.id
LEFT JOIN movie_companies_agg mco
    ON mco.movie_id = t.id
LEFT JOIN movie_keywords_agg mk
    ON mk.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY total_cast_members DESC
LIMIT 20
