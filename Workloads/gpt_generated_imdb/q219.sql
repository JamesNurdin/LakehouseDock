WITH keyword_counts AS (
    SELECT kt.kind AS kind,
           k.keyword AS keyword,
           COUNT(DISTINCT t.id) AS movie_cnt
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY kt.kind, k.keyword
),
ranked_keywords AS (
    SELECT kind,
           keyword,
           movie_cnt,
           ROW_NUMBER() OVER (PARTITION BY kind ORDER BY movie_cnt DESC) AS rn
    FROM keyword_counts
)
SELECT kind,
       keyword,
       movie_cnt
FROM ranked_keywords
WHERE rn <= 3
ORDER BY kind, movie_cnt DESC
