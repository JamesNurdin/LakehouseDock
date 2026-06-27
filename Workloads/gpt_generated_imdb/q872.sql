WITH movie_metrics AS (
    SELECT
        t.id AS movie_id,
        kt.kind AS kind,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN name n
        ON ci.person_id = n.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    GROUP BY t.id, kt.kind, t.production_year
)
SELECT
    kind,
    production_year,
    COUNT(*) AS movie_count,
    AVG(total_cast) AS avg_total_cast,
    AVG(male_cast) AS avg_male_cast,
    AVG(female_cast) AS avg_female_cast,
    AVG(company_count) AS avg_companies_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie
FROM movie_metrics
WHERE production_year IS NOT NULL
GROUP BY kind, production_year
ORDER BY movie_count DESC
LIMIT 30
