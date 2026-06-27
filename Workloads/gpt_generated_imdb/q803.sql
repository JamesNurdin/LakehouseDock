WITH movies_kw AS (
    SELECT
        kw.keyword,
        t.id AS movie_id,
        t.production_year,
        cn.id AS company_id
    FROM title t
    JOIN kind_type kt ON kt.id = t.kind_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword kw ON kw.id = mk.keyword_id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name cn ON cn.id = mc.company_id
    WHERE t.production_year > 2000
      AND kt.kind = 'movie'
)
SELECT
    keyword,
    COUNT(DISTINCT movie_id) AS movie_count,
    AVG(production_year) AS avg_production_year,
    COUNT(DISTINCT company_id) AS distinct_company_count
FROM movies_kw
GROUP BY keyword
ORDER BY movie_count DESC
LIMIT 10
