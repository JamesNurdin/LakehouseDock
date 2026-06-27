WITH cast_per_movie AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_per_movie AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
info_per_movie AS (
    SELECT
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT
    t.production_year,
    COUNT(DISTINCT t.id) AS num_movies,
    AVG(cp.cast_count) AS avg_cast_per_movie,
    AVG(kp.keyword_count) AS avg_keywords_per_movie,
    AVG(ip.info_type_count) AS avg_info_types_per_movie
FROM title t
LEFT JOIN cast_per_movie cp ON cp.movie_id = t.id
LEFT JOIN keyword_per_movie kp ON kp.movie_id = t.id
LEFT JOIN info_per_movie ip ON ip.movie_id = t.id
WHERE t.production_year IS NOT NULL
  AND t.kind_id = 1
GROUP BY t.production_year
ORDER BY t.production_year
