WITH keyword_decade_counts AS (
    SELECT
        k.id AS keyword_id,
        k.keyword,
        floor(t.production_year / 10) * 10 AS decade_start,
        COUNT(DISTINCT mk.movie_id) AS movie_count
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year IS NOT NULL
    GROUP BY k.id, k.keyword, floor(t.production_year / 10) * 10
)
SELECT
    kd.keyword,
    kd.decade_start,
    kd.movie_count,
    row_number() OVER (PARTITION BY kd.decade_start ORDER BY kd.movie_count DESC) AS rank_in_decade
FROM keyword_decade_counts kd
WHERE kd.movie_count >= 10
ORDER BY kd.decade_start, rank_in_decade
LIMIT 50
