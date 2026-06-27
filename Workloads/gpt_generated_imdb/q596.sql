WITH movies AS (
    SELECT t.id AS movie_id,
           t.production_year,
           k.kind
    FROM title t
    JOIN kind_type k ON t.kind_id = k.id
    WHERE t.production_year IS NOT NULL
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(*) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(*) AS comp_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_facts AS (
    SELECT mi.movie_id,
           MAX(CASE WHEN it.info = 'budget' THEN TRY_CAST(mi.info AS double) END) AS budget,
           MAX(CASE WHEN it.info = 'runtime' THEN TRY_CAST(mi.info AS double) END) AS runtime
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
),
keywords_group AS (
    SELECT m.production_year,
           m.kind,
           COUNT(DISTINCT mk.keyword_id) AS distinct_keywords
    FROM movies m
    JOIN movie_keyword mk ON mk.movie_id = m.movie_id
    GROUP BY m.production_year, m.kind
),
movie_agg AS (
    SELECT
        m.production_year,
        m.kind,
        COUNT(DISTINCT m.movie_id) AS total_movies,
        COALESCE(AVG(c.cast_cnt), 0) AS avg_cast_per_movie,
        COALESCE(AVG(p.comp_cnt), 0) AS avg_companies_per_movie,
        COALESCE(AVG(f.budget), 0) AS avg_budget,
        COALESCE(AVG(f.runtime), 0) AS avg_runtime
    FROM movies m
    LEFT JOIN cast_counts c ON c.movie_id = m.movie_id
    LEFT JOIN company_counts p ON p.movie_id = m.movie_id
    LEFT JOIN movie_facts f ON f.movie_id = m.movie_id
    GROUP BY m.production_year, m.kind
)
SELECT
    a.production_year,
    a.kind,
    a.total_movies,
    a.avg_cast_per_movie,
    a.avg_companies_per_movie,
    a.avg_budget,
    a.avg_runtime,
    COALESCE(g.distinct_keywords, 0) AS distinct_keywords
FROM movie_agg a
LEFT JOIN keywords_group g ON g.production_year = a.production_year AND g.kind = a.kind
ORDER BY a.production_year DESC, a.kind
