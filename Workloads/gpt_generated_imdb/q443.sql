/*
  Analytical query: average number of distinct keywords and distinct cast members per movie genre.
  The query aggregates per‑movie counts of keywords and cast members, then rolls these up
  to the genre level (info_type.info = 'genre'). It returns the top 10 genres with the
  highest average keyword count.
*/
WITH per_movie AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt,
        COUNT(DISTINCT ci.person_id) AS cast_cnt,
        t.production_year
    FROM title t
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id                     -- movie_keyword.movie_id = title.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id                     -- cast_info.movie_id = title.id
    GROUP BY t.id, t.production_year
)
SELECT
    it.info AS genre,
    COUNT(DISTINCT pm.movie_id) AS num_movies,
    AVG(pm.keyword_cnt) AS avg_keywords_per_movie,
    AVG(pm.cast_cnt) AS avg_cast_per_movie,
    AVG(pm.production_year) AS avg_production_year
FROM per_movie pm
JOIN movie_info mi
    ON mi.movie_id = pm.movie_id                 -- movie_info.movie_id = title.id
JOIN info_type it
    ON it.id = mi.info_type_id                   -- movie_info.info_type_id = info_type.id
WHERE it.info = 'genre'
GROUP BY it.info
ORDER BY avg_keywords_per_movie DESC
LIMIT 10
