/*
  Analytical query: For each movie, compute the total number of cast members and the number of distinct characters played.
  Then rank movies within each kind (e.g., movie, tvSeries) and production year by cast size.
*/
WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        kt.kind AS kind,
        t.production_year AS production_year,
        COUNT(ci.person_id) AS cast_size,
        COUNT(DISTINCT cn.id) AS distinct_character_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN char_name cn
        ON ci.person_role_id = cn.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, kt.kind, t.production_year
)
SELECT
    movie_id,
    movie_title,
    kind,
    production_year,
    cast_size,
    distinct_character_count,
    DENSE_RANK() OVER (PARTITION BY kind, production_year ORDER BY cast_size DESC) AS cast_rank
FROM movie_cast_counts
ORDER BY kind, production_year DESC, cast_rank
