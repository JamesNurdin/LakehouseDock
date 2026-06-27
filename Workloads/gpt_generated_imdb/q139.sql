-- Movies per year and genre with cast‑size and female‑presence metrics
WITH movies_genre AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        mi.info AS genre
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genre'
),
cast_stats AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT n.id) AS cast_size,
        MAX(CASE WHEN n.gender = 'F' THEN 1 ELSE 0 END) AS female_present
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
)
SELECT
    mg.production_year,
    mg.genre,
    COUNT(DISTINCT mg.movie_id) AS movie_count,
    AVG(cs.cast_size) AS avg_cast_size,
    AVG(cs.female_present) AS pct_movies_with_female
FROM movies_genre mg
JOIN cast_stats cs ON cs.movie_id = mg.movie_id
GROUP BY mg.production_year, mg.genre
ORDER BY movie_count DESC, mg.production_year DESC
LIMIT 100
