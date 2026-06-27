WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS kw_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
        AND kt.kind = 'movie'
    LEFT JOIN cast_info ci
        ON t.id = ci.movie_id
    LEFT JOIN movie_keyword mk
        ON t.id = mk.movie_id
    LEFT JOIN movie_companies mc
        ON t.id = mc.movie_id
    LEFT JOIN company_type ct
        ON mc.company_type_id = ct.id
    GROUP BY t.id, t.production_year
)
SELECT
    production_year,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(kw_count) AS avg_keywords_per_movie,
    AVG(company_count) AS avg_companies_per_movie,
    COUNT(*) AS movie_count
FROM movie_stats
GROUP BY production_year
ORDER BY avg_keywords_per_movie DESC
LIMIT 10
