WITH keyword_stats AS (
    SELECT
        k.id AS keyword_id,
        k.keyword,
        COUNT(DISTINCT mk.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        MIN(t.production_year) AS earliest_production_year,
        MAX(t.production_year) AS latest_production_year
    FROM keyword k
    JOIN movie_keyword mk ON mk.keyword_id = k.id
    JOIN title t ON mk.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY k.id, k.keyword
),
ranked_keyword_stats AS (
    SELECT
        keyword_id,
        keyword,
        movie_count,
        avg_production_year,
        earliest_production_year,
        latest_production_year,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS keyword_rank
    FROM keyword_stats
)
SELECT
    keyword_id,
    keyword,
    movie_count,
    avg_production_year,
    earliest_production_year,
    latest_production_year,
    keyword_rank
FROM ranked_keyword_stats
WHERE keyword_rank <= 20
ORDER BY keyword_rank
