WITH movie_keyword_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
),
company_movies AS (
    SELECT
        mc.company_id,
        mc.movie_id
    FROM movie_companies mc
    JOIN title t ON t.id = mc.movie_id
    WHERE t.production_year >= 2000
)
SELECT
    cn.id AS company_id,
    cn.name AS company_name,
    cn.country_code,
    COUNT(DISTINCT cm.movie_id) AS movie_count,
    COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
    AVG(mkc.keyword_count) AS avg_keywords_per_movie
FROM company_name cn
JOIN company_movies cm ON cm.company_id = cn.id
LEFT JOIN cast_info ci ON ci.movie_id = cm.movie_id
LEFT JOIN movie_keyword_counts mkc ON mkc.movie_id = cm.movie_id
GROUP BY cn.id, cn.name, cn.country_code
ORDER BY movie_count DESC
LIMIT 10
