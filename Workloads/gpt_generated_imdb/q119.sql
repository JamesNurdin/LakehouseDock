WITH cast_counts AS (
    SELECT t.id AS movie_id,
           t.production_year,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
    GROUP BY t.id, t.production_year
),
keyword_counts AS (
    SELECT t.id AS movie_id,
           t.production_year,
           COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
    GROUP BY t.id, t.production_year
)
SELECT c.production_year,
       AVG(c.cast_cnt) AS avg_cast_per_movie,
       AVG(k.kw_cnt) AS avg_keywords_per_movie
FROM cast_counts c
JOIN keyword_counts k ON c.movie_id = k.movie_id
GROUP BY c.production_year
ORDER BY c.production_year DESC
