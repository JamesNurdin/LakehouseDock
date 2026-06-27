WITH movie_stats AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        COUNT(DISTINCT mk.keyword_id) AS num_keywords,
        MAX(CASE WHEN it.info = 'budget' THEN mi.info END) AS budget,
        MAX(CASE WHEN it.info = 'runtime' THEN mi.info END) AS runtime
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    WHERE t.production_year >= 2000
      AND kt.kind = 'movie'
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    production_year,
    COUNT(*) AS num_movies,
    AVG(num_companies) AS avg_companies,
    AVG(num_keywords) AS avg_keywords,
    AVG(CAST(budget AS DOUBLE)) AS avg_budget,
    AVG(CAST(runtime AS DOUBLE)) AS avg_runtime
FROM movie_stats
GROUP BY production_year
HAVING COUNT(*) >= 5
ORDER BY production_year
