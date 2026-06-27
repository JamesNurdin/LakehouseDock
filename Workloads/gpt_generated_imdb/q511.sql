WITH keyword_usage AS (
    SELECT
        k.id,
        k.keyword,
        k.phonetic_code,
        COUNT(DISTINCT mk.movie_id) AS distinct_movie_cnt,
        COUNT(*) AS total_link_cnt,
        AVG(mk.movie_id) AS avg_movie_id
    FROM movie_keyword mk
    JOIN keyword k
      ON mk.keyword_id = k.id
    GROUP BY k.id, k.keyword, k.phonetic_code
)
SELECT
    id,
    keyword,
    phonetic_code,
    distinct_movie_cnt,
    total_link_cnt,
    avg_movie_id,
    RANK() OVER (ORDER BY distinct_movie_cnt DESC, total_link_cnt DESC) AS usage_rank
FROM keyword_usage
WHERE distinct_movie_cnt >= 5
ORDER BY usage_rank
LIMIT 20
