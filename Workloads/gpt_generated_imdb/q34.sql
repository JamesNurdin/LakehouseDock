/*
  Analytical query: For each movie kind (e.g., movie, TV series, etc.)
  – total number of distinct movies
  – average number of distinct cast members per movie
  – the top 3 most frequent character roles (by name) across all movies of that kind
*/
WITH movie_cast AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        ci.person_id,
        cn.name AS role_name
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN char_name cn ON ci.person_role_id = cn.id
),
movie_counts AS (
    SELECT
        movie_id,
        kind,
        COUNT(DISTINCT person_id) AS cast_count
    FROM movie_cast
    GROUP BY movie_id, kind
),
kind_stats AS (
    SELECT
        kind,
        COUNT(DISTINCT movie_id) AS total_movies,
        AVG(cast_count) AS avg_cast_per_movie
    FROM movie_counts
    GROUP BY kind
),
role_counts AS (
    SELECT
        kind,
        role_name,
        COUNT(*) AS role_appearances
    FROM movie_cast
    GROUP BY kind, role_name
),
top_roles AS (
    SELECT
        kind,
        role_name,
        role_appearances,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY role_appearances DESC) AS rn
    FROM role_counts
)
SELECT
    ks.kind,
    ks.total_movies,
    ks.avg_cast_per_movie,
    tr.role_name,
    tr.role_appearances
FROM kind_stats ks
JOIN top_roles tr ON ks.kind = tr.kind
WHERE tr.rn <= 3
ORDER BY ks.kind, tr.rn
