WITH keyword_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id
),
company_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name cn ON cn.id = mc.company_id
    GROUP BY t.id
),
cast_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id
)
SELECT
    kt.kind AS genre,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(cc.company_count, 0)) AS avg_companies_per_movie,
    AVG(COALESCE(ccast.cast_count, 0)) AS avg_cast_per_movie,
    AVG(t.production_year) AS avg_production_year
FROM title t
JOIN kind_type kt ON kt.id = t.kind_id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN company_counts cc ON cc.movie_id = t.id
LEFT JOIN cast_counts ccast ON ccast.movie_id = t.id
GROUP BY kt.kind
ORDER BY movie_count DESC
LIMIT 10
