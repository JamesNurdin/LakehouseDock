WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_cnt,
        COUNT(DISTINCT mc.company_id) AS company_cnt,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    COUNT(*) AS movie_cnt,
    AVG(cast_cnt) AS avg_cast_per_movie,
    AVG(company_cnt) AS avg_companies_per_movie,
    AVG(keyword_cnt) AS avg_keywords_per_movie,
    approx_percentile(cast_cnt, 0.5) AS median_cast_cnt
FROM movie_stats
WHERE production_year IS NOT NULL
GROUP BY production_year, kind
ORDER BY production_year DESC, kind
LIMIT 100
