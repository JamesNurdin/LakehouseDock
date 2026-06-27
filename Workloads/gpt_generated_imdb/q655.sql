WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) FILTER (WHERE mc.company_type_id = 1) AS production_company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year BETWEEN 2000 AND 2020
      AND kt.kind = 'movie'
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    kind,
    COUNT(*) AS total_movies,
    AVG(cast_count) AS avg_cast_per_movie,
    approx_percentile(cast_count, 0.5) AS median_cast_per_movie,
    AVG(production_company_count) AS avg_production_companies_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    approx_percentile(keyword_count, 0.5) AS median_keyword_per_movie,
    SUM(CASE WHEN cast_count > 5 THEN 1 ELSE 0 END) AS movies_with_many_cast,
    MIN(production_year) AS earliest_year,
    MAX(production_year) AS latest_year
FROM movie_stats
GROUP BY kind
ORDER BY total_movies DESC
