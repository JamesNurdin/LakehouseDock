WITH keyword_stats AS (
    SELECT
        mk.keyword_id,
        COUNT(DISTINCT mk.movie_id) AS movie_count,
        COUNT(DISTINCT t.title) AS distinct_title_count,
        MIN(t.production_year) AS min_production_year,
        MAX(t.production_year) AS max_production_year,
        AVG(t.production_year) AS avg_production_year
    FROM movie_keyword mk
    JOIN title t
        ON mk.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY mk.keyword_id
)
SELECT
    ks.keyword_id,
    ks.movie_count,
    ks.distinct_title_count,
    ks.min_production_year,
    ks.max_production_year,
    ks.avg_production_year,
    RANK() OVER (ORDER BY ks.movie_count DESC) AS movie_count_rank
FROM keyword_stats ks
ORDER BY ks.movie_count DESC
LIMIT 20
