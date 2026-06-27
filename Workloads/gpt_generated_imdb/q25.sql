/*
  Analytical query: For each production year, list the top 3 movies with the highest number of credited cast members.
  - Joins cast_info to title on cast_info.movie_id = title.id
  - Filters out uncredited roles (where note contains 'uncredited')
  - Aggregates cast counts per movie
  - Ranks movies within each year by cast count
*/
WITH movie_cast AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    WHERE t.production_year IS NOT NULL
      AND (ci.note IS NULL OR ci.note NOT LIKE '%uncredited%')
    GROUP BY t.id, t.title, t.production_year
),
ranked_movies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rn
    FROM movie_cast
)
SELECT
    production_year,
    movie_id,
    title,
    cast_count
FROM ranked_movies
WHERE rn <= 3
ORDER BY production_year, cast_count DESC
