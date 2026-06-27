WITH movie_agg AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        kt.kind AS kind,
        t.production_year AS production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mi.info) AS genre_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id AND it.info = 'genre'
    GROUP BY t.id, t.title, kt.kind, t.production_year
)
SELECT
    kind,
    production_year,
    COUNT(movie_id) AS movie_count,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    AVG(company_count) AS avg_companies_per_movie,
    AVG(genre_count) AS avg_genres_per_movie
FROM movie_agg
WHERE production_year IS NOT NULL AND production_year >= 2000
GROUP BY kind, production_year
ORDER BY avg_cast_per_movie DESC
LIMIT 10
