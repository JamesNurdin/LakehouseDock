WITH genre_info AS (
    SELECT mi.movie_id, it.info AS genre
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'Genre'
),
rating_info AS (
    SELECT mi.movie_id, CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'Rating'
),
budget_info AS (
    SELECT mi.movie_id, CAST(mi.info AS double) AS budget
    FROM movie_info_idx mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'Budget'
),
cast_counts AS (
    SELECT ci.movie_id, COUNT(*) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id, COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    g.genre,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(cc.cast_cnt) AS avg_cast_per_movie,
    AVG(r.rating) AS avg_rating,
    AVG(b.budget) AS avg_budget,
    AVG(co.company_cnt) AS avg_company_per_movie
FROM title t
JOIN genre_info g ON g.movie_id = t.id
LEFT JOIN rating_info r ON r.movie_id = t.id
LEFT JOIN budget_info b ON b.movie_id = t.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_counts co ON co.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, g.genre
ORDER BY t.production_year DESC, movie_count DESC
LIMIT 100
