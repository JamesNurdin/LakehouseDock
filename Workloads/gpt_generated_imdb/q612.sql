WITH cast_counts AS (
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
movie_stats AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           kt.kind,
           COALESCE(cc.cast_count, 0) AS cast_count,
           COALESCE(kc.keyword_count, 0) AS keyword_count,
           COALESCE(compc.company_count, 0) AS company_count,
           (COALESCE(cc.cast_count, 0) + COALESCE(kc.keyword_count, 0) + COALESCE(compc.company_count, 0)) AS total_score
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_counts cc ON t.id = cc.movie_id
    LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
    LEFT JOIN company_counts compc ON t.id = compc.movie_id
    WHERE t.production_year >= 2000
)
SELECT movie_id,
       title,
       production_year,
       kind,
       cast_count,
       keyword_count,
       company_count,
       total_score
FROM movie_stats
ORDER BY total_score DESC
LIMIT 10
