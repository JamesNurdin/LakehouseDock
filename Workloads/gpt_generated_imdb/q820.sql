WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN co.id END) AS production_company_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN company_name co ON mc.company_id = co.id
    WHERE t.production_year BETWEEN 2000 AND 2020
      AND kt.kind = 'movie'
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    COUNT(*) AS num_movies,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    SUM(production_company_count) AS total_production_companies
FROM movie_stats
GROUP BY production_year, kind
ORDER BY production_year, kind
