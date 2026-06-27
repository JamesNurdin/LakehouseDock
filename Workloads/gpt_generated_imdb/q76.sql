WITH runtime_info AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT kt.kind AS kind,
       COUNT(DISTINCT t.id) AS total_movies,
       AVG(ri.runtime_minutes) AS avg_runtime_minutes,
       AVG(kc.keyword_cnt) AS avg_keywords_per_movie,
       AVG(cc.cast_cnt) AS avg_cast_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN runtime_info ri ON t.id = ri.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
GROUP BY kt.kind
ORDER BY avg_runtime_minutes DESC
