WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year
),
year_agg AS (
    SELECT
        production_year,
        COUNT(*) AS total_movies,
        AVG(cast_count) AS avg_cast_per_movie,
        AVG(keyword_count) AS avg_keywords_per_movie,
        SUM(keyword_count) AS total_keyword_occurrences
    FROM movie_stats
    WHERE production_year IS NOT NULL
    GROUP BY production_year
),
keyword_year_counts AS (
    SELECT
        t.production_year,
        k.keyword,
        COUNT(DISTINCT mk.movie_id) AS movies_with_keyword
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, k.keyword
),
top_keyword_per_year AS (
    SELECT
        production_year,
        keyword,
        movies_with_keyword,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movies_with_keyword DESC) AS rn
    FROM keyword_year_counts
)
SELECT
    y.production_year,
    y.total_movies,
    ROUND(y.avg_cast_per_movie, 2) AS avg_cast_per_movie,
    ROUND(y.avg_keywords_per_movie, 2) AS avg_keywords_per_movie,
    t.keyword AS top_keyword,
    t.movies_with_keyword AS top_keyword_movie_count
FROM year_agg y
LEFT JOIN (
    SELECT production_year, keyword, movies_with_keyword
    FROM top_keyword_per_year
    WHERE rn = 1
) t ON t.production_year = y.production_year
ORDER BY y.production_year
