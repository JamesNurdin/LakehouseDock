WITH movie_metrics AS (
    SELECT
        t.id AS movie_id,
        k.kind AS genre,
        CAST(t.production_year AS integer) AS prod_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt,
        COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM title t
    JOIN kind_type k ON t.kind_id = k.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, k.kind, t.production_year
)
SELECT
    genre,
    prod_year,
    COUNT(*) AS movie_count,
    AVG(keyword_cnt) AS avg_keywords_per_movie,
    AVG(cast_cnt) AS avg_cast_per_movie
FROM movie_metrics
GROUP BY genre, prod_year
ORDER BY movie_count DESC
LIMIT 20
