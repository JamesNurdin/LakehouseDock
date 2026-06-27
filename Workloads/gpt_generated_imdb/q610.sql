WITH total_movies AS (
    SELECT COUNT(DISTINCT movie_id) AS total_movie_cnt
    FROM movie_keyword
),
keyword_counts AS (
    SELECT mk.keyword_id, COUNT(DISTINCT mk.movie_id) AS movie_cnt
    FROM movie_keyword mk
    GROUP BY mk.keyword_id
)
SELECT k.id,
       k.keyword,
       kc.movie_cnt,
       (kc.movie_cnt * 100.0 / tm.total_movie_cnt) AS pct_of_movies
FROM keyword_counts kc
JOIN keyword k
  ON kc.keyword_id = k.id
CROSS JOIN total_movies tm
WHERE kc.movie_cnt > 5
ORDER BY kc.movie_cnt DESC
LIMIT 10
