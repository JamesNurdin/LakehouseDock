WITH keyword_year_counts AS (
    SELECT
        t.production_year,
        k.id AS keyword_id,
        k.keyword,
        COUNT(DISTINCT mk.movie_id) AS movie_count
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY t.production_year, k.id, k.keyword
),
ranked_keywords AS (
    SELECT
        production_year,
        keyword,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rn
    FROM keyword_year_counts
)
SELECT
    production_year,
    keyword,
    movie_count
FROM ranked_keywords
WHERE rn = 1
ORDER BY production_year
