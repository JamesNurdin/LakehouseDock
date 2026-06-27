WITH movies AS (
    SELECT t.id AS movie_id,
           t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
),
cast_per_movie AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    JOIN movies m ON ci.movie_id = m.movie_id
    GROUP BY ci.movie_id
),
keyword_per_year AS (
    SELECT t.production_year,
           k.keyword,
           COUNT(DISTINCT t.id) AS movie_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
    GROUP BY t.production_year, k.keyword
),
ranked_keywords AS (
    SELECT production_year,
           keyword,
           movie_cnt,
           ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_cnt DESC) AS rn
    FROM keyword_per_year
)
SELECT
    m.production_year,
    COUNT(DISTINCT m.movie_id) AS movie_count,
    AVG(cp.cast_count) AS avg_cast_per_movie,
    rk.keyword AS top_keyword,
    rk.movie_cnt AS top_keyword_movie_count
FROM movies m
LEFT JOIN cast_per_movie cp ON m.movie_id = cp.movie_id
LEFT JOIN ranked_keywords rk ON m.production_year = rk.production_year AND rk.rn = 1
GROUP BY m.production_year, rk.keyword, rk.movie_cnt
ORDER BY m.production_year
