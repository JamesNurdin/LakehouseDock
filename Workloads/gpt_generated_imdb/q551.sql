WITH movie_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year, k.keyword
)

SELECT
    keyword,
    COUNT(DISTINCT movie_id) AS movie_cnt,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(company_count) AS avg_companies_per_movie,
    MIN(production_year) AS earliest_year,
    MAX(production_year) AS latest_year
FROM movie_counts
GROUP BY keyword
ORDER BY movie_cnt DESC
LIMIT 10
