WITH cast_per_movie AS (
    SELECT ci.movie_id AS movie_id,
           count(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_per_movie AS (
    SELECT mk.movie_id AS movie_id,
           count(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    t.production_year,
    kt.kind AS genre,
    count(DISTINCT t.id) AS movie_count,
    avg(coalesce(cp.cast_count, 0)) AS avg_cast_per_movie,
    avg(coalesce(kp.keyword_count, 0)) AS avg_keywords_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_per_movie cp ON t.id = cp.movie_id
LEFT JOIN keyword_per_movie kp ON t.id = kp.movie_id
WHERE t.production_year IS NOT NULL
  AND t.production_year >= 2000
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, kt.kind
