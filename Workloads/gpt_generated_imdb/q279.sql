/*
  Aggregates movie production metrics per production year and kind (e.g., movie, tvSeries).
  For each year/kind combination it returns:
    • total number of movies
    • distinct cast members across those movies
    • distinct keywords used
    • distinct production companies involved
    • average runtime (in minutes) when runtime information is available
*/
WITH movies_per_year AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
runtime_per_movie AS (
    SELECT
        mi.movie_id,
        TRY_CAST(mi.info AS integer) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
)
SELECT
    mpy.production_year,
    mpy.kind,
    COUNT(DISTINCT mpy.movie_id) AS total_movies,
    COUNT(DISTINCT ci.person_id) AS distinct_cast_members,
    COUNT(DISTINCT kw.keyword_id) AS distinct_keywords,
    COUNT(DISTINCT cn.id) AS distinct_companies,
    AVG(rpm.runtime_minutes) AS avg_runtime_minutes
FROM movies_per_year mpy
LEFT JOIN cast_info ci ON ci.movie_id = mpy.movie_id
LEFT JOIN movie_keyword kw ON kw.movie_id = mpy.movie_id
LEFT JOIN movie_companies mc ON mc.movie_id = mpy.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN runtime_per_movie rpm ON rpm.movie_id = mpy.movie_id
GROUP BY mpy.production_year, mpy.kind
ORDER BY mpy.production_year, mpy.kind
