WITH movie_cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    GROUP BY ci.movie_id
),
movie_company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    GROUP BY mc.movie_id
),
movie_keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    GROUP BY mk.movie_id
)
SELECT
    kt.kind AS kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    CAST(SUM(COALESCE(mcc.cast_count, 0)) AS double) / COUNT(DISTINCT t.id) AS avg_cast_per_movie,
    CAST(SUM(COALESCE(mcomp.company_count, 0)) AS double) / COUNT(DISTINCT t.id) AS avg_companies_per_movie,
    CAST(SUM(COALESCE(mkw.keyword_count, 0)) AS double) / COUNT(DISTINCT t.id) AS avg_keywords_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_cast_counts mcc ON t.id = mcc.movie_id
LEFT JOIN movie_company_counts mcomp ON t.id = mcomp.movie_id
LEFT JOIN movie_keyword_counts mkw ON t.id = mkw.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY kt.kind, t.production_year
