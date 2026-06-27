WITH keyword_movie_stats AS (
    SELECT
        k.id AS keyword_id,
        k.keyword,
        COUNT(DISTINCT mk.movie_id) AS movie_count,
        MIN(t.production_year) AS earliest_year,
        MAX(t.production_year) AS latest_year,
        AVG(t.production_year) AS avg_year
    FROM keyword k
    JOIN movie_keyword mk ON mk.keyword_id = k.id
    JOIN title t ON mk.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY k.id, k.keyword
)
SELECT
    keyword_id,
    keyword,
    movie_count,
    earliest_year,
    latest_year,
    avg_year,
    RANK() OVER (ORDER BY movie_count DESC) AS keyword_rank
FROM keyword_movie_stats
ORDER BY movie_count DESC
LIMIT 20
