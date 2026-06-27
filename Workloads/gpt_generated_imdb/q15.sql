WITH cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.kind_id,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.kind_id, t.production_year
),
keyword_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
),
company_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
)
SELECT
    kt.kind AS movie_kind,
    AVG(cc.cast_count) AS avg_cast_per_movie,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(compc.company_count, 0)) AS avg_companies_per_movie
FROM cast_counts cc
LEFT JOIN keyword_counts kc ON cc.movie_id = kc.movie_id
LEFT JOIN company_counts compc ON cc.movie_id = compc.movie_id
JOIN kind_type kt ON cc.kind_id = kt.id
GROUP BY kt.kind
ORDER BY avg_cast_per_movie DESC
LIMIT 10
