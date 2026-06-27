WITH genre_movies AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        it.info AS genre
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON it.id = mi.info_type_id
    WHERE it.info = 'genre'
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        COUNT(DISTINCT mc.company_type_id) AS num_company_types
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    gm.production_year,
    gm.genre,
    COUNT(*) AS num_movies,
    AVG(cc.num_companies) AS avg_companies_per_movie,
    AVG(cc.num_company_types) AS avg_company_types_per_movie
FROM genre_movies gm
JOIN company_counts cc ON cc.movie_id = gm.movie_id
WHERE gm.production_year >= 2000
GROUP BY gm.production_year, gm.genre
ORDER BY gm.production_year DESC, num_movies DESC
