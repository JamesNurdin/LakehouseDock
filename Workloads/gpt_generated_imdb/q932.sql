WITH cast_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id
),
company_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id
),
keyword_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id
)
SELECT
    kt.kind AS kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(cc.cast_count) AS avg_cast_per_movie,
    AVG(compc.company_count) AS avg_companies_per_movie,
    AVG(kc.keyword_count) AS avg_keywords_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_counts compc ON compc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY kt.kind, t.production_year
