WITH movie_metrics AS (
    SELECT
        t.id AS movie_id,
        t.title,
        kt.kind,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        MAX(CASE WHEN mi.info_type_id = 101 THEN CAST(mi.info AS DOUBLE) END) AS runtime_minutes,
        MAX(CASE WHEN mi.info_type_id = 102 THEN CAST(mi.info AS DOUBLE) END) AS budget_usd,
        MAX(CASE WHEN mi_idx.info_type_id = 200 THEN CAST(mi_idx.info AS DOUBLE) END) AS rating_score
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN movie_info_idx mi_idx ON mi_idx.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, kt.kind, t.production_year
)
SELECT
    kind,
    production_year,
    COUNT(*) AS total_movies,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(company_count) AS avg_companies_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    AVG(runtime_minutes) AS avg_runtime_minutes,
    AVG(budget_usd) AS avg_budget_usd,
    AVG(rating_score) AS avg_rating_score
FROM movie_metrics
GROUP BY kind, production_year
ORDER BY kind, production_year
