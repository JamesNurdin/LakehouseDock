WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt,
        COUNT(DISTINCT ci.person_id) AS cast_cnt,
        COUNT(DISTINCT mc.company_id) AS company_cnt,
        COUNT(DISTINCT cn.country_code) AS company_country_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    COUNT(*) AS movie_cnt,
    SUM(keyword_cnt) AS total_keywords,
    SUM(cast_cnt) AS total_cast_members,
    SUM(company_cnt) AS total_companies,
    SUM(company_country_cnt) AS total_company_countries,
    ROUND(SUM(keyword_cnt) * 1.0 / COUNT(*), 2) AS avg_keywords_per_movie,
    ROUND(SUM(cast_cnt) * 1.0 / COUNT(*), 2) AS avg_cast_per_movie,
    ROUND(SUM(company_cnt) * 1.0 / COUNT(*), 2) AS avg_companies_per_movie,
    ROUND(SUM(company_country_cnt) * 1.0 / COUNT(*), 2) AS avg_company_countries_per_movie
FROM movie_stats
WHERE production_year IS NOT NULL
GROUP BY production_year, kind
ORDER BY movie_cnt DESC
LIMIT 20
