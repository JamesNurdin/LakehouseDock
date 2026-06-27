WITH cast_counts AS (
    SELECT movie_id,
           count(DISTINCT person_id) AS cast_cnt
    FROM cast_info
    GROUP BY movie_id
)
SELECT
    t.production_year,
    it.info AS genre,
    count(DISTINCT t.id) AS movie_count,
    count(DISTINCT ci.person_id) AS distinct_actor_count,
    sum(cc.cast_cnt) / count(DISTINCT t.id) AS avg_cast_per_movie
FROM title t
JOIN movie_info mi ON mi.movie_id = t.id
JOIN info_type it ON it.id = mi.info_type_id
JOIN cast_info ci ON ci.movie_id = t.id
JOIN cast_counts cc ON cc.movie_id = t.id
WHERE it.info = 'genre'
  AND t.production_year IS NOT NULL
GROUP BY t.production_year, it.info
ORDER BY t.production_year, movie_count DESC
