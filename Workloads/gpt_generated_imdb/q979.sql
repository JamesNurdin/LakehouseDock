WITH keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    n.name,
    n.gender,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(cc.company_count, 0)) AS avg_companies_per_movie
FROM cast_info ci
JOIN name n
    ON ci.person_id = n.id
JOIN title t
    ON ci.movie_id = t.id
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN keyword_counts kc
    ON kc.movie_id = t.id
LEFT JOIN company_counts cc
    ON cc.movie_id = t.id
WHERE kt.kind = 'movie'
GROUP BY n.name, n.gender
ORDER BY movie_count DESC
LIMIT 10
