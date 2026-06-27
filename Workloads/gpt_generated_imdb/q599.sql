WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_info ci ON ci.movie_id = t.id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
),
ranked_movies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rn
    FROM movie_cast_counts
)
SELECT
    movie_id,
    title,
    production_year,
    cast_count
FROM ranked_movies
WHERE rn <= 3
ORDER BY production_year DESC, cast_count DESC
