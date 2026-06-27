WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT ct.kind) AS company_type_count
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        t.id,
        t.title,
        t.production_year,
        kt.kind
)
SELECT
    kind,
    production_year,
    COUNT(*) AS movie_cnt,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    AVG(company_count) AS avg_companies_per_movie,
    AVG(company_type_count) AS avg_company_types_per_movie
FROM movie_stats
WHERE production_year IS NOT NULL
GROUP BY
    kind,
    production_year
ORDER BY
    kind,
    production_year DESC
