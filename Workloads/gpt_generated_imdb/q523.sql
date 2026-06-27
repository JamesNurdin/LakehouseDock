WITH movie_aggregates AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    kind,
    COUNT(*) AS num_movies,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(company_count) AS avg_companies_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    MIN(production_year) AS earliest_year,
    MAX(production_year) AS latest_year
FROM movie_aggregates
WHERE production_year IS NOT NULL
GROUP BY kind
ORDER BY num_movies DESC
LIMIT 10
