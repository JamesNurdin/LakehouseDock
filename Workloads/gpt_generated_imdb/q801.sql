WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.kind AS kind,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT kw.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'production') AS production_company_count
    FROM title t
    JOIN kind_type k ON t.kind_id = k.id
    LEFT JOIN cast_info c ON c.movie_id = t.id
    LEFT JOIN movie_keyword kw ON kw.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY t.id, t.title, t.production_year, k.kind
)
SELECT
    production_year,
    kind,
    COUNT(*) AS movie_count,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    AVG(production_company_count) AS avg_production_companies_per_movie
FROM movie_stats
WHERE production_year IS NOT NULL
GROUP BY production_year, kind
ORDER BY production_year DESC, movie_count DESC
LIMIT 20
