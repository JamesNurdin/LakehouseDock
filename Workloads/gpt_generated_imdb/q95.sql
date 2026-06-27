WITH movies_cte AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
),
cast_cte AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_cte AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
keyword_cte AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k
        ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    m.kind,
    COUNT(*) AS num_movies,
    SUM(COALESCE(c.cast_count, 0)) AS total_distinct_cast,
    SUM(COALESCE(comp.company_count, 0)) AS total_distinct_companies,
    SUM(COALESCE(k.keyword_count, 0)) AS total_distinct_keywords,
    AVG(m.production_year) AS avg_production_year
FROM movies_cte m
LEFT JOIN cast_cte c
    ON c.movie_id = m.movie_id
LEFT JOIN company_cte comp
    ON comp.movie_id = m.movie_id
LEFT JOIN keyword_cte k
    ON k.movie_id = m.movie_id
GROUP BY m.kind
ORDER BY num_movies DESC
LIMIT 10
