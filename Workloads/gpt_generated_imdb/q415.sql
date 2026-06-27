WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year AS prod_year,
        kt.kind AS genre,
        COUNT(DISTINCT ci.person_id) AS cast_cnt,
        COUNT(DISTINCT mc.company_id) AS comp_cnt,
        COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM title AS t
    JOIN kind_type AS kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info AS ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_companies AS mc
        ON mc.movie_id = t.id
    LEFT JOIN movie_keyword AS mk
        ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    genre,
    COUNT(*) AS num_movies,
    AVG(cast_cnt) AS avg_cast_per_movie,
    AVG(comp_cnt) AS avg_companies_per_movie,
    AVG(kw_cnt) AS avg_keywords_per_movie
FROM movie_stats
GROUP BY genre
ORDER BY avg_cast_per_movie DESC
