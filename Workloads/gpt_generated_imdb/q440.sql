WITH movie_metrics AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.production_year
),
genre_counts AS (
    SELECT
        t.production_year,
        mi.info AS genre,
        COUNT(*) AS genre_movie_count
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON it.id = mi.info_type_id
    WHERE it.info = 'genre' AND t.production_year IS NOT NULL
    GROUP BY t.production_year, mi.info
),
top_genre_per_year AS (
    SELECT
        gc.production_year,
        gc.genre,
        gc.genre_movie_count,
        ROW_NUMBER() OVER (PARTITION BY gc.production_year ORDER BY gc.genre_movie_count DESC) AS rn
    FROM genre_counts gc
)
SELECT
    mm.production_year,
    COUNT(DISTINCT mm.movie_id) AS total_movies,
    AVG(mm.cast_count) AS avg_cast_per_movie,
    AVG(mm.keyword_count) AS avg_keywords_per_movie,
    AVG(mm.company_count) AS avg_companies_per_movie,
    tg.genre AS top_genre,
    tg.genre_movie_count AS top_genre_movie_count
FROM movie_metrics mm
LEFT JOIN top_genre_per_year tg
    ON tg.production_year = mm.production_year
    AND tg.rn = 1
GROUP BY mm.production_year, tg.genre, tg.genre_movie_count
ORDER BY mm.production_year
