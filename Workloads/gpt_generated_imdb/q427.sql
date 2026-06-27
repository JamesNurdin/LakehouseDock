WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT ct.kind) AS company_type_count,
        CASE
            WHEN COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN mc.company_id END) > 0 THEN 1
            ELSE 0
        END AS has_production_company
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    COUNT(DISTINCT movie_id) AS total_movies,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(company_count) AS avg_companies_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    AVG(company_type_count) AS avg_company_types_per_movie,
    AVG(has_production_company) AS pct_movies_with_production_company
FROM movie_stats
WHERE production_year BETWEEN 2000 AND 2020
GROUP BY production_year, kind
ORDER BY production_year, kind
