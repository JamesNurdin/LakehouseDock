WITH movie_counts AS (
    SELECT CAST(t.production_year AS integer) AS prod_year,
           COUNT(DISTINCT t.id) AS movie_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie' AND t.production_year >= 2000
    GROUP BY CAST(t.production_year AS integer)
),
cast_counts AS (
    SELECT CAST(t.production_year AS integer) AS prod_year,
           COUNT(*) AS cast_cnt
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie' AND t.production_year >= 2000
    GROUP BY CAST(t.production_year AS integer)
),
keyword_counts AS (
    SELECT CAST(t.production_year AS integer) AS prod_year,
           COUNT(*) AS kw_cnt
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie' AND t.production_year >= 2000
    GROUP BY CAST(t.production_year AS integer)
)
SELECT mc.prod_year,
       mc.movie_cnt,
       CAST(COALESCE(cc.cast_cnt, 0) AS double) / mc.movie_cnt AS avg_cast_per_movie,
       CAST(COALESCE(kc.kw_cnt, 0) AS double) / mc.movie_cnt AS avg_keywords_per_movie
FROM movie_counts mc
LEFT JOIN cast_counts cc ON mc.prod_year = cc.prod_year
LEFT JOIN keyword_counts kc ON mc.prod_year = kc.prod_year
ORDER BY mc.prod_year
