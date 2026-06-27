WITH movies AS (
    SELECT t.id AS movie_id,
           t.production_year,
           kt.kind AS kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
agg AS (
    SELECT
        m.production_year,
        m.kind,
        COUNT(*) AS movie_count,
        AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
        AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
        AVG(COALESCE(comc.company_count, 0)) AS avg_companies_per_movie
    FROM movies m
    LEFT JOIN cast_counts cc   ON m.movie_id = cc.movie_id
    LEFT JOIN keyword_counts kc ON m.movie_id = kc.movie_id
    LEFT JOIN company_counts comc ON m.movie_id = comc.movie_id
    GROUP BY m.production_year, m.kind
    HAVING COUNT(*) >= 10
)
SELECT
    a.production_year,
    a.kind,
    a.movie_count,
    a.avg_cast_per_movie,
    a.avg_keywords_per_movie,
    a.avg_companies_per_movie,
    RANK() OVER (PARTITION BY a.production_year ORDER BY a.movie_count DESC) AS kind_rank
FROM agg a
ORDER BY a.production_year DESC, a.kind
