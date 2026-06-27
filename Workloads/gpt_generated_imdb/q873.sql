/*
  Analytical query: for each combination of title kind (e.g., movie, short) and production year,
  compute the number of titles, average number of cast members, production companies, keywords,
  average runtime (in minutes) and average rating.
  The query respects the allowed join rules and uses only the listed tables/columns.
*/
WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
runtime_info AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
),
rating_agg AS (
    SELECT mi_idx.movie_id,
           AVG(mi_idx.note) AS avg_rating
    FROM movie_info_idx mi_idx
    JOIN info_type it ON mi_idx.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi_idx.movie_id
)
SELECT k.kind,
       t.production_year,
       COUNT(DISTINCT t.id) AS movie_count,
       AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
       AVG(COALESCE(compc.company_count, 0)) AS avg_companies_per_movie,
       AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
       AVG(r.runtime_minutes) AS avg_runtime_minutes,
       AVG(rating.avg_rating) AS avg_rating
FROM title t
JOIN kind_type k ON t.kind_id = k.id
LEFT JOIN cast_counts cc       ON cc.movie_id = t.id
LEFT JOIN company_counts compc ON compc.movie_id = t.id
LEFT JOIN keyword_counts kc    ON kc.movie_id = t.id
LEFT JOIN runtime_info r       ON r.movie_id = t.id
LEFT JOIN rating_agg rating    ON rating.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY k.kind, t.production_year
ORDER BY k.kind, t.production_year
