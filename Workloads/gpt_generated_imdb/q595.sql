WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        kt.kind AS genre,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
)
SELECT
    mc.production_year,
    mc.genre,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    AVG(mc.cast_count) AS avg_cast_per_movie,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(cc.company_count, 0)) AS avg_production_companies_per_movie
FROM movie_cast_counts mc
LEFT JOIN movie_keyword_counts kc ON kc.movie_id = mc.movie_id
LEFT JOIN movie_company_counts cc ON cc.movie_id = mc.movie_id
WHERE mc.production_year IS NOT NULL
  AND mc.production_year >= 2000
GROUP BY mc.production_year, mc.genre
ORDER BY mc.production_year DESC, total_movies DESC
LIMIT 100
