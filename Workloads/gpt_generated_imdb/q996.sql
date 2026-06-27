/*
  Analytical query: For each title kind (e.g., movie, tvSeries, tvEpisode) compute
  - the number of titles,
  - the average number of distinct cast members per title,
  - the average runtime (minutes) when a runtime info record exists,
  - the average production year.
  Results are ordered by the number of titles and limited to the top 10 kinds.
*/
WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
runtime_info AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS DOUBLE) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
)
SELECT
    kt.kind,
    COUNT(t.id) AS movie_count,
    AVG(cc.cast_count) AS avg_cast_per_movie,
    AVG(r.runtime_minutes) AS avg_runtime_minutes,
    AVG(t.production_year) AS avg_production_year
FROM title t
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN cast_counts cc
    ON cc.movie_id = t.id
LEFT JOIN runtime_info r
    ON r.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind
ORDER BY movie_count DESC
LIMIT 10
