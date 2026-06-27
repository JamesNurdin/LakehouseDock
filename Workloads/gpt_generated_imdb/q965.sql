WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2000
    GROUP BY t.id, t.production_year
)
SELECT
    production_year,
    COUNT(*) AS total_movies,
    AVG(cast_count) AS avg_cast_per_movie,
    SUM(keyword_count) AS total_keywords
FROM movie_stats
GROUP BY production_year
ORDER BY production_year
